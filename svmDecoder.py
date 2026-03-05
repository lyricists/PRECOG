# Import library

import glob, json, pickle
import numpy as np
from sklearn.model_selection import KFold
from sklearn.svm import SVC
from sklearn.decomposition import PCA
from sklearn.metrics import balanced_accuracy_score
from sklearn.preprocessing import StandardScaler
import mat73
from scipy.signal import decimate
from tqdm import tqdm


class SVM_decoder:
    def __init__(
        self,
        fpath: str = None,
        bPath: str = None,
        fileName: str = None,
        IdxName: str = None,
        logName: str = None,
        sentiName: str = None,
        chName: str = None,
        k_fold: int = 5,
        numPC: int = None,
        Trial_num: int = None,
        avg_num: int = None,
        state: int = 42,
        saveName: str = None,
    ):

        self.fpath = fpath
        self.bPath = bPath
        self.logName = logName
        self.IdxName = IdxName
        self.fileName = fileName
        self.sentiName = sentiName
        self.chName = chName
        self.kfold = k_fold
        self.state = state
        self.Trial_num = Trial_num
        self.numPC = numPC
        self.avg_num = avg_num
        self.saveName = saveName

        self.Decoder()

    # Data load
    def load_EEG(self):
        print("Loading dataset")
        # Load EEG dataset
        with open(self.fpath + self.fileName, "rb") as file:
            self.Dataset = pickle.load(file)

        # Load subject index
        self.subIdx = mat73.loadmat(self.bPath + self.IdxName)["subject_index"]

        # Load channel file
        self.goodCh = mat73.loadmat(self.bPath + self.chName)["Channel"].astype(int) - 1

        # Load sentence index
        with open(self.bPath + self.logName, "rb") as file:
            self.senId = pickle.load(file)["Sentiment"]

        self.Dataset = self.Dataset[self.goodCh, :, :, :]

    # Within-subject trial train test split
    def train_test_split(self):
        print("Performing train test split")
        skf = KFold(n_splits=self.kfold, shuffle=True, random_state=self.state)

        self.split_data = []

        for n in tqdm(range(len(self.subIdx))):

            posIdx = self.senId[n]["positive"]
            negIdx = self.senId[n]["negative"]

            pIdx_data = []
            nIdx_data = []

            for ptrain_index, ptest_index in skf.split(posIdx):
                fold_data = {"train": posIdx[ptrain_index], "test": posIdx[ptest_index]}
                pIdx_data.append(fold_data)

            for ntrain_index, ntest_index in skf.split(negIdx):
                fold_data = {"train": negIdx[ntrain_index], "test": negIdx[ntest_index]}
                nIdx_data.append(fold_data)

            self.split_data.append({"positive": pIdx_data, "negative": nIdx_data})

    # Computing PCA
    def compute_PCA(self):
        self.pcaModel = []

        print("Computing PCA")
        for k in tqdm(range(self.kfold)):
            pcaInput = []

            cPos = []
            cNeg = []
            dPos = []
            dNeg = []
            sPos = []
            sNeg = []

            for n in range(len(self.subIdx)):

                if self.subIdx[n] == 1:
                    cPos.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["positive"][k]["train"]
                            ],
                            axis=2,
                        )
                    )
                    cNeg.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["negative"][k]["train"]
                            ],
                            axis=2,
                        )
                    )

                elif self.subIdx[n] == 2:
                    dPos.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["positive"][k]["train"]
                            ],
                            axis=2,
                        )
                    )
                    dNeg.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["negative"][k]["train"]
                            ],
                            axis=2,
                        )
                    )

                else:
                    sPos.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["positive"][k]["train"]
                            ],
                            axis=2,
                        )
                    )
                    sNeg.append(
                        np.mean(
                            self.Dataset[:, :, :, n][
                                :, :, self.split_data[n]["negative"][k]["train"]
                            ],
                            axis=2,
                        )
                    )

            pcaInput = np.concatenate(
                (
                    (np.mean(np.array(cPos), axis=0) + np.mean(np.array(cNeg), axis=0))
                    / 2,
                    (np.mean(np.array(dPos), axis=0) + np.mean(np.array(dNeg), axis=0))
                    / 2,
                    (np.mean(np.array(sPos), axis=0) + np.mean(np.array(sNeg), axis=0))
                    / 2,
                ),
                axis=1,
            )

            pca = PCA(n_components=self.numPC)
            pca.fit(pcaInput.T)

            pca_weights = {"pcaCoeff": pca.components_, "pcaModel": pca}

            self.pcaModel.append(pca_weights)

    # Projecting to latent space
    def projectPCA(self):
        print("PCA projection")
        n_components = self.numPC

        Dataset = self.Dataset
        n_channels = Dataset.shape[0]
        data_shape = list(Dataset.shape)
        channel_axis = data_shape.index(n_channels)

        self.pcaDataset = []

        for k in tqdm(range(self.kfold)):
            # Compute the PCA on transformed array
            X_transform_pca = Dataset.reshape(n_channels, -1).T
            X_transform_pca = self.pcaModel[k]["pcaModel"].transform(X_transform_pca)

            X_shape = list(data_shape)
            X_shape[channel_axis] = n_components
            X_transform_pca = X_transform_pca.T.reshape(X_shape)

            self.pcaDataset.append({"pcaData": X_transform_pca})

    # Data augmentation (Bootstrapping)
    def augData(self):
        self.augDataset = []
        print("Data augmentation")

        for n in tqdm(range(len(self.subIdx))):
            foldData = []

            for k in range(self.kfold):
                tmpPos = []
                tmpNeg = []

                for i in range(int(self.Trial_num * 0.8)):
                    rIdx = np.random.choice(
                        len(self.split_data[n]["positive"][k]["train"]), self.avg_num
                    )
                    tmpPos.append(
                        np.mean(
                            self.pcaDataset[k]["pcaData"][
                                :,
                                :,
                                self.split_data[n]["positive"][k]["train"][rIdx],
                                n,
                            ],
                            axis=2,
                        )
                    )

                    rIdx = np.random.choice(
                        len(self.split_data[n]["negative"][k]["train"]), self.avg_num
                    )
                    tmpNeg.append(
                        np.mean(
                            self.pcaDataset[k]["pcaData"][
                                :,
                                :,
                                self.split_data[n]["negative"][k]["train"][rIdx],
                                n,
                            ],
                            axis=2,
                        )
                    )

                TrainData = np.concatenate(
                    (
                        np.array(tmpPos).transpose(1, 2, 0),
                        np.array(tmpNeg).transpose(1, 2, 0),
                    ),
                    axis=2,
                )

                tmpPos = []
                tmpNeg = []
                for i in range(int(self.Trial_num * 0.2)):
                    rIdx = np.random.choice(
                        len(self.split_data[n]["positive"][k]["test"]), self.avg_num
                    )
                    tmpPos.append(
                        np.mean(
                            self.pcaDataset[k]["pcaData"][
                                :, :, self.split_data[n]["positive"][k]["test"][rIdx], n
                            ],
                            axis=2,
                        )
                    )

                    rIdx = np.random.choice(
                        len(self.split_data[n]["negative"][k]["test"]), self.avg_num
                    )
                    tmpNeg.append(
                        np.mean(
                            self.pcaDataset[k]["pcaData"][
                                :, :, self.split_data[n]["negative"][k]["test"][rIdx], n
                            ],
                            axis=2,
                        )
                    )

                TestData = np.concatenate(
                    (
                        np.array(tmpPos).transpose(1, 2, 0),
                        np.array(tmpNeg).transpose(1, 2, 0),
                    ),
                    axis=2,
                )

                foldData.append({"TrainData": TrainData, "TestData": TestData})

            self.augDataset.append(foldData)

    # Generating class for augmented trials
    def genClass(self):
        train_class = np.concatenate(
            (
                np.zeros(int(self.Trial_num * 0.8), dtype=int),
                np.ones(int(self.Trial_num * 0.8), dtype=int),
            )
        )
        test_class = np.concatenate(
            (
                np.zeros(int(self.Trial_num * 0.2), dtype=int),
                np.ones(int(self.Trial_num * 0.2), dtype=int),
            )
        )

        self.classIdx = {"Train": train_class, "Test": test_class}

    # SVM decoder
    def classifier(self, trainData, testData):
        x_train, x_test = trainData, testData
        y_train, y_test = self.classIdx["Train"], self.classIdx["Test"]

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

        # Feature weight
        weight = clf.coef_.flatten()

        # Test
        pred = clf.predict(x_test)
        score = balanced_accuracy_score(y_test, pred)

        return score, weight

    # Saving data
    def saveData(self):
        Results = {
            "split_data": self.split_data,
            "pcaModel": self.pcaModel,
            "augDataset": self.augDataset,
            "decodeScore": self.Results["Decode"],
            "weight": self.Results["Weight"],
            "subIdx": self.subIdx,
        }

        with open(
            "/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Code/Decoding/svm/Result/"
            + self.saveName,
            "wb",
        ) as file:
            pickle.dump(Results, file)

    def Decoder(self):

        # Load EEG data
        self.load_EEG()

        # Train test split
        self.train_test_split()

        # PCA
        self.compute_PCA()
        self.projectPCA()

        # Data augmentation
        self.augData()
        self.genClass()

        # Classifying

        decode = []
        feature_weight = []

        print("Performing svm decoding")
        for n in tqdm(range(len(self.subIdx))):

            sub_decode = []
            sub_weight = []

            for k in range(self.kfold):

                score = []
                weight = []

                for t in range(self.Dataset.shape[1]):

                    tmpScore, tmpWeight = self.classifier(
                        self.augDataset[n][k]["TrainData"][:, t, :],
                        self.augDataset[n][k]["TestData"][:, t, :],
                    )

                    score.append(tmpScore)
                    weight.append(tmpWeight)

                sub_decode.append(score)
                sub_weight.append(weight)

            decode.append(np.mean(np.array(sub_decode), axis=0))
            feature_weight.append(np.mean(np.array(sub_weight), axis=0))

        self.Results = {"Decode": np.array(decode), "Weight": np.array(feature_weight)}

        print("Save data")
        self.saveData()


if __name__ == "__main__":
    svm = SVM_decoder(
        fpath="/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Data/Preprocessed data/",  # EEG data directory
        bPath="/Users/woojaejeong/Desktop/Data/USC/DARPA-NEAT/Data/Behavior/",  # Behavioral data directory
        fileName="Data_sen_lepoch_full.pkl",  # EEG data
        IdxName="subject_index.mat",  # Subject index
        logName="senIdx_congruent.pkl",  # Trial index
        chName="GoodChannel.mat",  # Channel index
        numPC=3,  # Number of PC components
        Trial_num=250,  # Number of augmented trials
        avg_num=12,  # Number of subaveraged trials in bootstrapping
        saveName="svmDecoding_sentiment_sen_3pc_lepoch_linear_commonPCA_full.pkl",
    )
