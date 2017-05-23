VENV=.venv
VDIR=$(PWD)/$(VENV)


clean:
	@find . -name \*.pyc -exec rm {} \;
	@find . -name "results.xml" -exec rm {} \;
	@find . -name \*.py,cover -exec rm {} \;
	@find . -name \*.log -exec rm {} \;
	@rm -rf ./src/{htmlcov,.coverage,coverage.xml}


python_env:
	if [ ! -f $(VDIR)/bin/python ]; then \
		echo "Creating virtual environment $(VENV)"; \
		virtualenv -p python3 --prompt="(spiffe_pki)" $(VDIR); \
		(. $(VDIR)/bin/activate && easy_install --upgrade pip); \
	fi


dev_requirements: python_env
	@echo "Installing test requirements"
	(. $(VDIR)/bin/activate && \
	 pip install -r requirements/dev.txt)
