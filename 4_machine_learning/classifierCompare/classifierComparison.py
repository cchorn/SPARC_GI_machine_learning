# script to run grid search for optimal hyperparameters, train-test SVM and kNN classifiers for each feature set per subject and log to local mongo DB

# Author: Ameya C. Nanivadekar
# email: acnani@gmail.com 

import pymongo
import itertools
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import RepeatedKFold
from sklearn.decomposition import PCA
from sklearn.feature_selection import RFE
import random
import warnings
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import GridSearchCV

warnings.filterwarnings("ignore")

mongohost = "192.168.0.246"
mongoport = 15213
collection = 'acute'

client = pymongo.MongoClient(mongohost, mongoport)
db = client.ferret
collection2 = db.MLresults_wideGamma

names = ["Nearest Neighbors", "Linear SVM"]

def getFeats(subject, signalType, states = [1,2,3,4,5,6,7], feats = [1,2,3,4,5,6,7,8,9], location = ['S1','S2','S3','S4','pD','dD']):
    result = db.command({
            'aggregate': collection,
            'pipeline': [
                {'$match': {
                    "mdf_def.mdf_type": 'feature',
                    "mdf_metadata.subject": subject,
                    "mdf_metadata.state": {"$in": states},
                    "mdf_metadata.feature": {"$in": feats},
                    "mdf_metadata.signalType": signalType,
                    "mdf_metadata.location": {"$in": location}
                }},
                {"$group": {
                    "_id": {"state": "$mdf_metadata.state"},
                    "featVal": {"$push":"$mdf_metadata.featVal"},
                    # "feature": {"$push": "$mdf_metadata.feature"},
                    "count": {"$sum":1}
                }},
                {"$project": {
                    "_id": 1,
                    "count": "$count",
                    "featVal": "$featVal",
                    # "feature":"$feature"
                }}]})

    outDict = {}
    tmp = []
    for iRes in result['result']:
        state = iRes['_id']['state']
        outDict[state] = np.reshape(iRes['featVal'],(-1,len(feats)))
        tmp.append(outDict[state].shape[0])

    if outDict:
        outDict['numObservations'] = min(tmp)
    else:
        outDict['numObservations'] = 0

    return outDict

def getReducedFeats(dataX, dataY, ifeat):
    X = []
    selectedFeats = []
    if ifeat in [3, 5]:
        regressor = SVC(kernel="linear")
        rfe = RFE(regressor, ifeat)
        X = rfe.fit_transform(dataX, dataY)
        for i in np.argwhere(rfe._get_support_mask()):
            selectedFeats.extend(i+1)

    elif ifeat == 'all':
        X = dataX
        selectedFeats = 'all'

    elif ifeat == 'pca':
        pca = PCA(n_components=0.9)
        X = pca.fit_transform(dataX)
        selectedFeats = 'pca'

    return X, selectedFeats


allFeats = [1,2,3,4,5,6,9]
featureCombos = []
for iFeat in allFeats:
    featureCombos.extend(list(itertools.combinations(allFeats, iFeat)))

allSubs = ['14-18']
signalType = ['PA']
stateCombos = [[4,5]]

# allSubs = ['16-18','13-18','15-18']
# signalType = ['PA','PA','bPA',]
# stateCombos = [[7,4,5], [7,4,5], [7,4,5]]
featureExtract = ['all']

conditions = []
for iSubs, iStates, sigType in zip(allSubs, stateCombos, signalType):
    locs = db.acute.find({'mdf_metadata.subject':iSubs, 'mdf_metadata.signalType':sigType}).distinct('mdf_metadata.location')
    for iLoc in locs:
        for reducedFeat in featureExtract:
            for iFeat in featureCombos:
                for clfName in names:
                    conditions.append([iSubs, iStates, iLoc, 'all', clfName, sigType, iFeat])


totalIters = len(conditions)
for iNum in conditions:

    ctr = conditions.index(iNum)
    # print str(datetime.datetime.now()) + ' ' + str(ctr) + ' of ' + str(totalIters)

    iSubs = iNum[0]
    iStates = iNum[1]
    iLoc = iNum[2]
    iFeats = iNum[3]
    name = iNum[4]
    sigType = iNum[5]
    featList = iNum[6]
    targetFeats = getFeats(iSubs, sigType, states=list(iStates), feats = featList, location=[iLoc])
    numPoints = targetFeats['numObservations']
    if numPoints >= 5:
        tmp = []
        for iKey in iStates:
            stateFeat = targetFeats[iKey]
            np.random.shuffle(stateFeat)
            tmp.append(np.concatenate((stateFeat[0:numPoints, :], iKey * np.ones([numPoints, 1])), axis=1))

        dataMatrix = np.concatenate(tmp)
        X = dataMatrix[:, :-1]
        y = dataMatrix[:, -1]
        y_jumbled = np.array(random.sample(y, len(y)))

        X, selectedFeats = getReducedFeats(X, y, iFeats)

        rkf = RepeatedKFold(n_splits=5, n_repeats=100)
        accuracyList = []
        accuracyList2 = []
        bestParamList = []
        confMat = np.zeros([len(iStates),len(iStates)])
        # confMat2 = []
        for train_index, test_index in rkf.split(X):
            # X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
            X_train, X_test = X[train_index], X[test_index]
            y_train, y_test = y[train_index], y[test_index]
            y_train_jumbled, y_test_jumbled = y_jumbled[train_index], y_jumbled[test_index]
            bestParams = {}

            if name == 'Nearest Neighbors':
                clfBest = KNeighborsClassifier()
                # clfBest.fit(X_train, y_train)
                tuned_parameters = {'n_neighbors': range(1, 10)}
                grid = GridSearchCV(clfBest, tuned_parameters, cv=5, scoring='accuracy', n_jobs=-1) #
                tmp = grid.fit(X_train, y_train)
                clfBest = tmp.best_estimator_
                bestParams = tmp.best_params_

            elif name == "Linear SVM":
                clfBest = SVC()
                # clfBest.fit(X_train, y_train)
                tuned_parameters = [{'kernel': ['rbf'], 'gamma': [1e-3, 1e-4],'C': [1, 10, 100, 1000]},
                                    {'kernel': ['linear'], 'C': [1, 10, 100, 1000]}]
                grid = GridSearchCV(clfBest, tuned_parameters, cv=5, scoring='accuracy', n_jobs=-1) #
                tmp = grid.fit(X_train, y_train)
                clfBest = tmp.best_estimator_
                bestParams = tmp.best_params_

            ypred = clfBest.predict(X_test)
            accuracyList.append(clfBest.score(X_test, y_test))
            bestParamList.append(bestParams)
            confMat += confusion_matrix(y_test, ypred, labels=iStates)

            # clfBest_copy2 = clfBest
            # clfBest_copy.fit(X_train, y_train_jumbled)
            # ypred2 = clfBest_copy.predict(X_test)
            # accuracyList2.append(clfBest_copy.score(X_test, y_test_jumbled))
            # # confMat2.append(classification_report(y_test_jumbled, ypred2, output_dict=True, target_names=[str(int(i)) for i in list(np.unique( [list(y_test_jumbled), list(ypred2)]))]))


        MLresult = {}
        MLresult['attempt'] = 'MLresults_wideGamma'
        MLresult['index'] = ctr
        MLresult['subject'] = iSubs
        MLresult['states'] = iStates
        MLresult['locs'] = iLoc
        MLresult['feats'] = featList
        MLresult['classifier'] = name

        MLresult['numObservations'] = numPoints
        MLresult['accuracyList'] = accuracyList
        MLresult['confMat'] = list(np.ndarray.flatten(confMat))

        if name == "Linear SVM":
            for iVal in bestParamList:
                MLresult.setdefault('C', []).append(iVal['C'])
                MLresult.setdefault('kernel',[]).append(iVal['kernel'])
                if iVal['kernel'] == 'rbf':
                    MLresult.setdefault('gamma',[]).append(iVal['gamma'])

        else:
            for iVal in bestParamList:
                MLresult.setdefault('n_neighbors',[]).append(iVal['n_neighbors'])

        # MLresult['accuracyList_jumbled'] = accuracyList2
        # MLresult['report_jumbled'] = confMat2

        collection2.insert_one(MLresult)
        print ctr, featList ,iSubs, iLoc,name,np.mean(accuracyList)


    else:
        print 'skipping ' + str(iSubs) + str(iStates) + str(iLoc) + str(iFeats) + ' numPoints = ' + str(numPoints)
