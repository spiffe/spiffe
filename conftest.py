import docker
import glob
import os
import pytest

class ImageBuilder(object):
	"""A class to build test modules images"""
	def __init__(self, docker, modules):
		"""Initialize with docker client and a list of modules"""
		self._docker = docker
		self._modules = modules
		self._images = []

	def run(self):
		"""Discover available modules and build each one"""
		for module in self._modules:
			if not os.path.isfile(os.path.join(module, "Dockerfile")):
				continue
			self.build(module)

	def build(self, module_path):
		"""Build an image for the requested module"""
		module_name = os.path.basename(module_path)
		build_params = {
			"path": os.path.abspath(module_path),
			"rm": True,
			"forcerm": True,
			"tag": "spiffe:{0}".format(module_name)
		}
		new_image = self._docker.images.build(**build_params)
		self._images.append(new_image)

	def cleanup(self):
		"""Remove all module images"""
		for image in list(self._images):
			try:
				self._docker.images.remove(image.short_id)
				self._images.remove(image)
			except docker.errors.ImageNotFound:
				continue

	@property
	def images(self):
		"""Accessor containing all built images"""
		return self._images

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
		self._imageBuilder = ImageBuilder(self._docker, self._modules)
		self._imageBuilder.run()

	def runc(self, image, params):
		"""Expose docker run"""
		self._docker.containers.run(image, **params)

	def cleanup(self):
		"""Remove the images we built"""
		self._imageBuilder.cleanup()

	@property
	def images(self):
		"""Returns list of all built images"""
		return self._imageBuilder.images

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
		"""Returns the helper's ImageBuilder instance"""
		return self._imageBuilder

# Begin test config
helper = SuiteHelper(docker.from_env())

def pytest_configure(config):
	helper.prepare()

def pytest_unconfigure(config):
	helper.cleanup()

def pytest_generate_tests(metafunc):
	metafunc.parametrize("image", helper.images)
	if "good_org" in metafunc.fixturenames:
		metafunc.parametrize("good_org", helper.good_orgs)
	elif "bad_org" in metafunc.fixturenames:
		metafunc.parametrize("bad_org", helper.bad_orgs)

@pytest.fixture
def runner():
	return helper.runc
