import configparser


COUNTRY_NAME = "countryName"
LOCALITY_NAME = "localityName"
STATE_OR_PROVINCE_NAME = "stateOrProvinceName"
ORGANIZATION_NAME = "organizationName"
COMMON_NAME = "commonName"

SECTION_SUBJECT_NAME = "subject_name"
SECTION_EXTENSIONS = "extensions"
HOSTNAME = "hostname"
SPIFFE_ID = "spiffeID"

class SpiffeConfig(object):

    def __init__(self,
                 config_file):
        """
        @param config_file
        """
        self._config_file = config_file

        self._country = ""
        self._state_or_province = ""
        self._locality = ""
        self._organization = ""
        self._common_name = ""

        self._hostname = ""
        self._spiffeID = ""
        self._parser = None

    @property
    def config_file(self):
        return self._config_file

    @property
    def country(self):
        return self._country

    @property
    def state_or_province(self):
        return self._state_or_province

    @property
    def locality(self):
        return self._locality

    @property
    def organization(self):
        return self._organization

    @property
    def common_name(self):
        return self._common_name

    @property
    def hostname(self):
        return self._hostname

    @property
    def spiffeID(self):
        return self._spiffeID

    @property
    def parser(self):
        return self._parser

    def load(self):

        try:
            self._parser = configparser.ConfigParser()
            self._parser.read(self.config_file)


            self._country = self.get(SECTION_SUBJECT_NAME,
                                     COUNTRY_NAME)

            self._state_or_province = self.get(SECTION_SUBJECT_NAME,
                                               STATE_OR_PROVINCE_NAME)

            self._locality = self.get(SECTION_SUBJECT_NAME,
                                      LOCALITY_NAME)

            self._organization = self.get(SECTION_SUBJECT_NAME,
                                            ORGANIZATION_NAME)

            self._common_name = self.get(SECTION_SUBJECT_NAME,
                                         COMMON_NAME)

            self._hostname = self.get(SECTION_EXTENSIONS,
                                      HOSTNAME)

            self._spiffeID = self.get(SECTION_EXTENSIONS,
                                      SPIFFE_ID)

        except Exception as exp:
            # TODO: Logging
            raise exp


    def get(self, section, field):

        return self.parser.get(section, field)

    def get_list(self, section, field, delimiter=','):

        # Delimiters are "," by default
        field = self.parser.get(section, field)

        return field.split(delimiter)







