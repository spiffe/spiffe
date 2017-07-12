.PHONY: all generate verify clean
export PYTHONDONTWRITEBYTECODE = 1

default: all

all: .venv generate verify

.venv:
	virtualenv .venv
	.venv/bin/pip install pytest
	.venv/bin/pip install pytest-xdist
	.venv/bin/pip install pyflakes
	.venv/bin/pip install docker

lint:
	.venv/bin/pyflakes *.py

generate:
	make -C generate setup build generate clean_exited

verify: .venv
	.venv/bin/pytest -n 4 --junitxml=test_report.xml --tb=line

clean:
	rm -r ./.venv
	rm -r ./.certs
