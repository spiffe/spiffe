.PHONY: all generate verify clean
export PYTHONDONTWRITEBYTECODE = 1

default: all

all: .venv generate verify

.venv:
	virtualenv .venv --always-copy
	.venv/bin/pip install pytest
	.venv/bin/pip install pytest-xdist
	.venv/bin/pip install pyflakes
	.venv/bin/pip install docker

lint:
	.venv/bin/pyflakes *.py

generate:
	make -C generate setup build generate clean_exited

verify: .venv
	mkdir -p test_results
	.venv/bin/pytest -n 1 \
	--tb=line \
	--junitxml=test_results/report.xml

clean:
	rm -r ./.venv
	rm -r ./.certs
