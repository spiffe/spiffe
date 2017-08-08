import docker
import os
import pytest

class TestSuite(object):
	def test_good_cert(self, good_org, module, runner):
		"""Test the given org cert and module, assert that it passes"""
		image = module["image"]
		expected_failures = module["expected_failures"]
		run_params = {
			"remove": True,
			"volumes": {
				os.path.abspath(good_org): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}


		cert_name = os.path.basename(good_org)

		# Check for expected failure
		if cert_name in expected_failures:
			msg = "Skipping cert {0} for module {1}; reason: {2}"
			msg = msg.format(cert_name, image.tags[0], expected_failures[cert_name])
			pytest.xfail(msg)

		try:
			runner(image, run_params)
			assert True
		except docker.errors.ContainerError:
			msg = "Valid cert {0} failed validation in module {1}!"
			msg = msg.format(cert_name, image.tags[0])
			assert False, msg

	def test_bad_cert(self, bad_org, module, runner):
		"""Test the given org cert and module, assert that it fails"""
		image = module["image"]
		expected_failures = module["expected_failures"]
		run_params = {
			"remove": True,
			"volumes": {
				os.path.abspath(bad_org): {
					"bind": "/certs",
					"mode": "ro"
				}
			}
		}

		cert_name = os.path.basename(bad_org)

		# Check for expected failure
		if cert_name in expected_failures:
			msg = "Skipping cert {0} for module {1}; reason: {2}"
			msg = msg.format(cert_name, image.tags[0], expected_failures[cert_name])
			pytest.xfail(msg)

		msg = "Invalid cert {0} succeeded validation in module {1}!"
		msg = msg.format(cert_name, image.tags[0])
		with pytest.raises(docker.errors.ContainerError, message=msg):
			runner(image, run_params)
