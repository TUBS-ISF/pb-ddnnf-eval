# Reproduction Package for Empirical Evaluation on Pseudo-Boolean d-DNNF Compilation
This reproduction package can be used to reproduce and replicate the results of the empirical evaluation conducted in our TSE article `Tackling Expressive Feature-Modeling Constructs
with Pseudo-Boolean d-DNNF Compilation`.

## Repository Structure

The repository consists of the following main components:

- `converter`: Java Tool for converting UVL models to DIMACS and OPB formats
- `jobs`: Scripts for running the evaluation
- `models`: Input models for the evaluation
- `results`: Results as evaluated on a Slurm cluster

## How to Reproduce

> [!NOTE]  
> This evaluation contains computationally demanding tasks.
> When running it on all models in this repository, it can take many hours or multiple days to complete.

This reproduction package comes in two variants:
One using the Slurm scheduling system, which was originally used for this evaluation.
The alternative is a local version, not depending on Slurm such that it can be run on a wide range of systems.
By default, the Slurm mode is used when the `squeue` command is found.
Otherwise the local mode is used.

> [!TIP]
> The mode can be overridden using the `SLURM_MODE` environment variable: `slurm` or `local`

This evaluation is split in multiple steps:

| Step          | Description                          | Depends on    |
| ------------- | ------------------------------------ | ------------- |
| `dimacs`      | Converts UVL models to DIMACS        |               |
| `opb`         | Converts UVL models to OPB           |               |
| `opb_pbcount` | Adapts OPB models for `pbcount`      | `opb`         |
| `d4`          | Compiles DIMACS to d-DNNF using `d4` | `dimacs`      |
| `p2d`         | Compiles OPB to d-DNNF using `p2d`   | `opb`         |
| `pbcount`     | Counts OPB using `pbcount`           | `opb_pbcount` |
| `count_d4`    | Counts d4 d-DNNF using `ddnnife`     | `d4`          |
| `count_p2d`   | Counts p2d d-DNNF using `ddnnife`    | `p2d`         |
| `collect`     | Collects all results into a CSV      | all above     |

### Slurm

**Requirements:**

- [Slurm][slurm]
- [Apptainer][apptainer]

The Slurm variant of this evaluation by default uses `apptainer` to run a container containing all the necessary tools.
As Slurm jobs can run in parallel, not all steps can be started at the same time due to the dependencies mentioned above.
Inside the `jobs` directory, use the following to start Slurm jobs for any given task:

```
./run.sh ../models/<models path> <output> <task>
```

where

- `models path` is the path to the set of models to evaluate
- `output` is a directory where to place output files (needs to be re-used between steps)
- `task` is one of the steps described above

The `output` task will place the CSV at `<output>/results.csv`.

### Local

> [!IMPORTANT]  
> Results of the local mode are not directly comparable to those compiled using Slurm.
> The setup running the evaluation is quite different.

**Requirements:**

- [Podman][podman]

The local variant uses Podman to run the container.
The same `./run.sh` script as with Slurm can be used.
Alternatively, a `Makefile` is present in the root of this repository for running all steps after another:

```
make isolated
```

The command above will run all steps for the isolated models.
Other available targets are `literature`, `synthesized` and `all` (default) for running all three.
When using the `Makefile`, the output will be placed at `out`.

[slurm]: https://slurm.schedmd.com
[apptainer]: https://apptainer.org
[podman]: https://podman.io
