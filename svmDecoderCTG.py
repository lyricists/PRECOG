# Import library

import glob, json, pickle
import numpy as np
from sklearn.svm import SVC
from sklearn.metrics import balanced_accuracy_score
from sklearn.preprocessing import StandardScaler
from tqdm import tqdm


class SVM_CTG:
    def __init__(self, fpath: str = None, fName: str = None, sName: str = None):
        self.fpath = fpath
        self.fName = fName
        self.sName = sName
        self.svmCTG()

    def load_dataset(self):
        with open(self.fpath + self.fName, "rb") as file:
            self.Results = pickle.load(file)

        self.numSub = len(self.Results["augDataset"])
        self.kfold = len(self.Results["augDataset"][0])

    def genClass(self):
        trainNum = self.Results["augDataset"][0][0]["TrainData"].shape[2]
        testNum = self.Results["augDataset"][0][0]["TestData"].shape[2]

        train_class = np.concatenate(
            (
                np.zeros(int(trainNum / 2), dtype=int),
                np.ones(int(trainNum / 2), dtype=int),
            )
        )
        test_class = np.concatenate(
            (
                np.zeros(int(testNum / 2), dtype=int),
                np.ones(int(testNum / 2), dtype=int),
            )
        )

        return train_class, test_class

    def classifier(self, trainData, testData, classTrain, classTest):
        x_train, x_test = trainData, testData
        y_train, y_test = classTrain, classTest

        rIdx_train, rIdx_test = np.arange(x_train.shape[1]), np.arange(x_test.shape[1])
        np.random.shuffle(rIdx_train), np.random.shuffle(rIdx_test)

        x_train, x_test = x_train[:, rIdx_train], x_test[:, rIdx_test]
        y_train, y_test = y_train[rIdx_train], y_test[rIdx_test]

        scalar = StandardScaler()

        x_train = scalar.fit_transform(x_train.transpose(1, 0))
        x_test = scalar.transform(x_test.transpose(1, 0))

        # Train
        clf = SVC(
            kernel="linear",
            C=1,
            gamma="auto",
            class_weight="balanced",
            tol=1e-3,
            random_state=42,
        )
        clf.fit(x_train, y_train)

        # Test
        pred = clf.predict(x_test)
        score = balanced_accuracy_score(y_test, pred)

        return score

    def saveData(self, Data, n):
        Results = {"ctgDecode": Data}

        print(f"Saving sub{n+1:03d} data")
        with open(self.fpath + "CTG/" + f"sub{n+1:03d}_" + self.sName, "wb") as file:
            pickle.dump(Results, file)

    def svmCTG(self):

        # Load data
        print("Load dataset")
        self.load_dataset()

        # Generate class
        print("Generate class")
        train_class, test_class = self.genClass()

        print("Running SVM decoding CTG")
        for n in tqdm(range(self.numSub)):

            sub_decode = []

            for k in tqdm(range(self.kfold)):

                inputTrain = self.Results["augDataset"][n][k]["TrainData"]
                inputTest = self.Results["augDataset"][n][k]["TestData"]

                score = []

                for t1 in range(inputTrain.shape[1]):
                    tmp = []

                    for t2 in range(inputTest.shape[1]):
                        tmp.append(
                            self.classifier(
                                inputTrain[:, t1, :],
                                inputTest[:, t2, :],
                                train_class,
                                test_class,
                            )
                        )

                    score.append(tmp)

                sub_decode.append(score)

            Results = np.array(sub_decode)

            self.saveData(Results, n)


if __name__ == "__main__":
    ctg = SVM_CTG(
        fpath="/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/",  # Decoding file directory
        fName="svmDecoding_sentiment_sen_3pc_lepoch_congruency_linear_commonPCA.pkl",  # Decoding File
        sName="svmDecoding_CTG_sentiment_sen.pkl",  # Save file name
    )
