# Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation

## Repository Structure
The repository consists of the following main components:
* *final_results*: Contains the processed output of the results in the publication
* *iso_models*: Contains the feature models representing the expressive concepts in isolation
* *models*: Contains the basic industrial feature models
* *rnd_models*: Contains the randomly generated feature models containing different combinations of the concepts
* *lib*: Contains the external dependencies required for running the evaluation
* *eval.py*: Runner for the evaluation

Note that the industrial dataset is omitted in this repository due to confidentiality.

## How to Reproduce

The binaries provided have been tested on Ubuntu and Fedora only. Depending on your operating system you may need to recompile [d4](https://github.com/SoftVarE-Group/d4v2) and [p2d](https://github.com/TUBS-ISF/p2d).
For d4, there are pre-compiled binaries for several OS in their [CI/CD](https://github.com/SoftVarE-Group/d4v2/releases/tag/2.0.0).

Install dependencies: `pip3 install -r requirements.txt`

Evaluate on isolated models: `python3 eval.py isolated`

Evaluate on random models: `python3 eval.py random`

Evaluate on real-world model from [collection repository](https://github.com/SoftVarE-Group/feature-model-benchmark): `python3 eval.py repo`

Note that the empirical evaluation is computationally demanding. Depending on the dataset, the evaluation may take days of runtime and dozens of GB of memory on the drive.