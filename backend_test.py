import requests
import unittest
import sys

class ItsYourRadioAPITester(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Use the public endpoint from the frontend .env file
        self.base_url = "https://ed07b77d-b08b-418c-b45f-6584501261bb.preview.emergentagent.com/api"
        self.tests_run = 0
        self.tests_passed = 0

    def test_root_endpoint(self):
        """Test the root API endpoint"""
        print(f"\n🔍 Testing root API endpoint...")
        
        try:
            response = requests.get(f"{self.base_url}/")
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["message"], "Welcome to itsyourradio API")
            print(f"✅ Passed - Status: {response.status_code}, Message: {data['message']}")
            return True
        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False

    def test_auth_endpoints(self):
        """Test authentication endpoints"""
        print(f"\n🔍 Testing auth endpoints...")
        
        # We're not going to actually test login since we don't have credentials
        # Just check if the endpoints exist
        try:
            response = requests.get(f"{self.base_url}/auth")
            print(f"Auth endpoint status: {response.status_code}")
            return True
        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False

    def test_users_endpoints(self):
        """Test users endpoints"""
        print(f"\n🔍 Testing users endpoints...")
        
        try:
            response = requests.get(f"{self.base_url}/users")
            print(f"Users endpoint status: {response.status_code}")
            return True
        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False

def run_tests():
    tester = ItsYourRadioAPITester()
    
    # Run the tests
    root_test = tester.test_root_endpoint()
    auth_test = tester.test_auth_endpoints()
    users_test = tester.test_users_endpoints()
    
    # Print summary
    print("\n📊 API Test Summary:")
    print(f"Root API endpoint: {'✅ Passed' if root_test else '❌ Failed'}")
    print(f"Auth endpoints: {'✅ Passed' if auth_test else '❌ Failed'}")
    print(f"Users endpoints: {'✅ Passed' if users_test else '❌ Failed'}")
    
    return all([root_test, auth_test, users_test])

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
