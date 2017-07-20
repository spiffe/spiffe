import docker
import glob
import os
import pytest

class ModuleBuilder(object):
	"""A class to build test modules images"""
	def __init__(self, docker, modules):
		"""Initialize with docker client and a list of module paths"""
		self._docker = docker
		self._modules = {}
		for module in modules:
			self._modules[module] = {}

	def run(self):
		"""Discover available modules and build each one"""
		for module_path in self._modules.keys():
			if not os.path.isfile(os.path.join(module_path, "Dockerfile")):
				continue
			self.build(module_path)

	def build(self, module_path):
		"""Build an image for the requested module"""
		module = {}
		tag = "spiffe:{0}".format(os.path.basename(module_path))
		build_params = {
			"path": os.path.abspath(module_path),
			"rm": True,
			"forcerm": True,
			"tag": tag
		}

		new_image = self._docker.images.build(**build_params)
		expected_failures = self.load_expected_failures(module_path)
		module["image"] = new_image
		module["expected_failures"] = expected_failures
		self._modules[module_path] = module

	def load_expected_failures(self, module_path):
		expected_failures = []
		ef_file_path = os.path.join(module_path, "expected_failures")
		if os.path.isfile(ef_file_path):
			ef_file = open(ef_file_path, "r")
			expected_failures = ef_file.read().splitlines()
		return expected_failures

	def cleanup(self):
		"""Remove all module images"""
		for name, module in list(self._modules.items()):
			image = module["image"]
			try:
				self._docker.images.remove(image.short_id)
				del self._modules[name]
			except docker.errors.ImageNotFound:
				del self._modules[name]
				continue

	@property
	def modules(self):
		"""Accessor containing all built images"""
		return self._modules

class SuiteHelper(object):
	"""A class which exposes helper methods for the test suite"""
	def __init__(self, docker, module_path="verify", cert_path=".certs"):
		"""Initialize with docker client and path to the modules"""
		self._module_path = module_path
		self._cert_path = cert_path
		self._docker = docker

	def prepare(self):
		"""Build data necessary to run the tests"""
		self._modules = glob.glob(os.path.join(self._module_path, "*"))
		self._goodCerts = glob.glob(os.path.join(self._cert_path, "good", "*"))
		self._badCerts = glob.glob(os.path.join(self._cert_path, "bad", "*"))
		self._moduleBuilder = ModuleBuilder(self._docker, self._modules)
		self._moduleBuilder.run()

	def runc(self, image, params):
		"""Wrap docker run to inject SPIFFE ID as arg"""
		org_path = params["volumes"].keys()[0]
		try:
			id_file = open(os.path.join(org_path, "spiffe-id.txt"), "r")
			spiffe_id = id_file.read()
			params["command"] = spiffe_id
		finally:
			id_file.close

		self._docker.containers.run(image, **params)

	def cleanup(self):
		"""Remove the images we built"""
		self._moduleBuilder.cleanup()

	@property
	def modules(self):
		"""Returns list of all built modules"""
		return self._moduleBuilder.modules

	@property
	def good_orgs(self):
		"""Returns list of all "good" org paths"""
		return self._goodCerts

	@property
	def bad_orgs(self):
		"""Returns list of all "bad" org paths"""
		return self._badCerts

	@property
	def builder(self):
		"""Returns the helper's ModuleBuilder instance"""
		return self._moduleBuilder

# Begin test config
helper = SuiteHelper(docker.from_env())

def pytest_configure(config):
	helper.prepare()

def pytest_unconfigure(config):
	helper.cleanup()

def pytest_generate_tests(metafunc):
	metafunc.parametrize("module", helper.modules.values())
	if "good_org" in metafunc.fixturenames:
		metafunc.parametrize("good_org", helper.good_orgs)
	elif "bad_org" in metafunc.fixturenames:
		metafunc.parametrize("bad_org", helper.bad_orgs)

@pytest.fixture
def runner():
	return helper.runc
