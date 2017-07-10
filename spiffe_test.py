import docker
import os
import pytest

class TestSuite:
	def test_good_cert(self, good_org, image, runner):
		"""Test the given org cert and module, assert that it passes"""
		run_params = {
			"remove": True,
			"volumes": {
				os.path.abspath(good_org): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		try:
			result = runner(image, run_params)
			assert True
		except docker.errors.ContainerError:
			assert False, "Validation failed with %s".format(result)

	def test_bad_cert(self, bad_org, image, runner):
		"""Test the given org cert and module, assert that it fails"""
		run_params = {
			"remove": True,
			"volumes": {
				os.path.abspath(bad_org): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}
		msg = "Invalid cert succeeded validation!"
		with pytest.raises(docker.errors.ContainerError, message=msg):
			runner(image, run_params)
