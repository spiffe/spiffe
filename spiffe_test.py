import docker
import glob
import os
import pytest

class ImageBuilder:
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

	def build(self, modulePath):
		"""Build an image for the requested module"""
		buildParams = {
			"path": os.path.abspath(modulePath),
			"rm": True,
			"forcerm": True
		}
		new_image = self._docker.images.build(**buildParams)
		self._images.append(new_image)

	def cleanup(self):
		"""Remove all module images"""
		for image in list(self._images):
			self._docker.images.remove(image.short_id)
			self._images.remove(image)

	@property
	def images(self):
		"""Accessor containing all built images"""
		return self._images	

class SuiteHelper:
	"""A class which exposes helper methods for the test suite"""
	def __init__(self, docker, modulePath="verify", certPath=".certs"):
		"""Initialize with docker client and path to the modules"""
		self._module_path = modulePath
		self._cert_path = certPath
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

class TestSuite:
	_helper = SuiteHelper(docker.from_env())
	_helper.prepare()

	def teardown_class(cls):
		TestSuite._helper.cleanup()

	@pytest.mark.parametrize("orgPath", _helper.good_orgs)
	@pytest.mark.parametrize("image", _helper.images)
	def test_good_cert(self, orgPath, image):
		"""Test the given cert and module, assert that it passes"""
		runParams = {
			"remove": True,
			"volumes": {
				os.path.abspath(orgPath): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		try:
			result = TestSuite._helper.runc(image, runParams)
			assert True
		except docker.errors.ContainerError:
			assert False, "Validation failed with %s".format(result)

	@pytest.mark.parametrize("orgPath", _helper.bad_orgs)
	@pytest.mark.parametrize("image", _helper.images)
	def test_bad_cert(self, orgPath, image):
		"""Test the given cert and module, assert that it fails"""
		runParams = {
			"remove": True,
			"volumes": {
				os.path.abspath(orgPath): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		msg = "Invalid cert succeeded validation!"
		with pytest.raises(docker.errors.ContainerError, message=msg):
			TestSuite._helper.runc(image, runParams)
