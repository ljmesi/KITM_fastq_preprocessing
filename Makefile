.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS := -e -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# The conda env definition file "env.yml" is located in the project's root directory
CURRENT_CONDA_ENV_NAME = KITM_trimming
ACTIVATE_CONDA = source $$(conda info --base)/etc/profile.d/conda.sh
CONDA_ACTIVATE = $(ACTIVATE_CONDA) ; conda activate ; conda activate $(CURRENT_CONDA_ENV_NAME)

DOC_DIR = /home/lauri/Desktop/KITM_fastq_preprocessing/pandoc

.PHONY: \
all \
run \
clean \
html \
snakefmt_fix \
snakelint \
update_env \
help


all: run


## run: Run snakemake pipeline
run:
	$(CONDA_ACTIVATE)
	snakemake \
	--cores 92 \
	--rerun-incomplete


## clean: Remove output files
clean:
	rm -frv \
	results \
	logs


## html: Create html documentation
html:
	$(ACTIVATE_CONDA) ; conda activate ; conda activate pandoc
	pandoc \
	--verbose \
	--standalone \
	--template $(DOC_DIR)/template.html \
	--css $(DOC_DIR)/css/styling.css \
	--toc \
	--metadata title="How to run KITM fastq preprocessing" \
	--metadata lang=en \
	-o documentation/run_KITM_fastq_preprocessing.html \
	run_KITM_fastq_preprocessing.md


## snakefmt_fix: Fix shortcomings found by snakefmt
snakefmt_fix:
	$(CONDA_ACTIVATE)
	snakefmt \
	"-l 130" \
	.


## snakelint: Lint snakemake scripts
snakelint:
	$(CONDA_ACTIVATE)
	snakemake \
	--lint


## update_env: Update conda env based on the env.yml file
update_env:
	$(ACTIVATE_CONDA)
	mamba env update --file env.yml --prune


## help: Show this message
help:
	@grep '^##' ./Makefile


## pycodestyle: Run pycodestyle with same settings as in CI
# pycodestyle:
# 	$(CONDA_ACTIVATE)
# 	pycodestyle \
# 	--max-line-length=130 \
# 	--statistics workflow/scripts


## typing: Run mypy on a Python script
# typing:
# 	$(CONDA_ACTIVATE)
# 	mypy \
# 	--ignore-missing-imports \
# 	$(PY_SCRIPTS)


## format: Format python scripts with yapf
# format:
# 	$(CONDA_ACTIVATE)
# 	yapf --in-place --verbose $(PY_SCRIPTS)
# 	# @echo
# 	# black --verbose $(PY_SCRIPTS)


