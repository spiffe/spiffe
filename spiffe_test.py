import docker
import pytest

class ImageBuilder
	"""A class to build test modules images"""
	def __init__(self, docker, modules):
		"""Initialize with docker client and a list of modules"""
		self._docker = docker
		self._modules = modules
		self._images = []

	def run(self):
		"""Discover available modules and build each one"""
		for module in self._modules:
			self.build(module)

	def build(self, modulePath):
		"""Build an image for the requested module"""
		buildParams = {
			"path": os.path.abspath(modulePath),
			"rm": true,
			"forcerm": true
		}
		new_image = self._docker.images.build(buildParams)
		self._images.append(new_image)

	def cleanup(self):
		"""Remove all module images"""
		for image in self._images:
			self._docker.images.remove(image)

	@property
	def images(self):
		"""Accessor containing all built images"""
		return self._images	

class SuiteHelper
	"""A class which exposes helper methods for the test suite"""
	def __init__(self, docker, modulePath="verify", certPath=".certs"):
		"""Initialize with docker client and path to the modules"""
		self._path = path
		self._docker = docker
	
	# def run(self):
	# 	"""Run the full suite"""
	# 	self.prepare
	# 	self.cleanup	

	def prepare(self):
		"""Build data necessary to run the tests"""
		self._modules = glob.glob(os.path.join(self._path, "*"))
		self._goodCerts = glob.glob(os.path.join(self._path, "good", "*"))
		self._badCerts = glob.glob(os.path.join(self._path, "bad", "*"))
		self._imageBuilder = ImageBuilder(self._docker, self._modules)
		self._imageBuilder.run

	def cleanup(self):
		"""Dont leave shit laying around"""
		self._imageBuilder.cleanup

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

class TestSuite
	# FIXME: Need to figure out how to init SuiteHelper and manage lifecycle
	@pytest.mark.parametrize("orgPath", SuiteHelper().good_orgs)
	@pytest.mark.parametrize("image", SuiteHelper().images)
	def test_good_cert(self, orgPath, image):
		"""Test the given cert and module, assert that it passes"""
		runParams = {
			"detach": true,
			"image": image,
			"volumes": {
				orgPath: {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		try:
			container = self._docker.containers.run(runParams)
			assert true
		except self._docker.errors.ContainerError:
			assert false, "Validation failed with %s".format(result)

	@pytest.mark.parametrize("orgPath", SuiteHelper().bad_orgs)
	@pytest.mark.parametrize("image", SuiteHelper().images)
	def test_bad_cert(self, orgPath, image):
		"""Test the given cert and module, assert that it fails"""
		runParams = {
			"image": image,
			"auto_remove": true,
			"volumes": {
				orgPath: {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		msg = "Invalid cert succeeded validation!"
		with pytest.raises(self._docker.errors.ContainerError, msg)
			self._docker.containers.run(runParams)
