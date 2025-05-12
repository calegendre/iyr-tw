import requests
import sys
import time

class RadioAPITester:
    def __init__(self, base_url="https://1a906595-8810-4dd1-a53b-8279808fe840.preview.emergentagent.com"):
        self.base_url = base_url
        self.api_url = f"{base_url}/api"
        self.token = None
        self.tests_run = 0
        self.tests_passed = 0

    def run_test(self, name, method, endpoint, expected_status, data=None, headers=None):
        """Run a single API test"""
        url = f"{self.api_url}/{endpoint}"
        if headers is None:
            headers = {'Content-Type': 'application/json'}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers)
            elif method == 'PUT':
                response = requests.put(url, json=data, headers=headers)
            elif method == 'DELETE':
                response = requests.delete(url, headers=headers)

            success = response.status_code == expected_status
            if success:
                self.tests_passed += 1
                print(f"✅ Passed - Status: {response.status_code}")
                try:
                    return success, response.json() if response.content else {}
                except:
                    return success, {}
            else:
                print(f"❌ Failed - Expected {expected_status}, got {response.status_code}")
                try:
                    error_content = response.json() if response.content else "No content"
                    print(f"Response: {error_content}")
                except:
                    print(f"Response: {response.text}")
                return False, {}

        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False, {}

    def test_health_check(self):
        """Test the health check endpoint"""
        return self.run_test(
            "Health Check",
            "GET",
            "health",
            200
        )

    def test_stream_info(self):
        """Test the stream info endpoint"""
        return self.run_test(
            "Stream Info",
            "GET",
            "stream/info",
            200
        )

    def test_now_playing(self):
        """Test the now playing endpoint"""
        return self.run_test(
            "Now Playing",
            "GET",
            "stream/now-playing",
            200
        )

    def test_login(self, email, password):
        """Test login and get token"""
        success, response = self.run_test(
            "Login",
            "POST",
            "auth/login",
            200,
            data={"email": email, "password": password}
        )
        if success and 'access_token' in response:
            self.token = response['access_token']
            return True
        return False

    def test_register(self, user_data):
        """Test user registration"""
        return self.run_test(
            "Register User",
            "POST",
            "auth/register",
            201,
            data=user_data
        )

    def test_get_user_profile(self):
        """Test getting user profile"""
        return self.run_test(
            "Get User Profile",
            "GET",
            "users/me",
            200
        )

def main():
    # Setup
    tester = RadioAPITester()
    
    # Run tests
    print("\n===== Testing ItsYourRadio Backend API =====\n")
    
    # Test health check
    health_success, health_data = tester.test_health_check()
    
    # Test stream info
    stream_info_success, stream_info_data = tester.test_stream_info()
    if stream_info_success:
        print(f"Stream Info: {stream_info_data}")
    
    # Test now playing
    now_playing_success, now_playing_data = tester.test_now_playing()
    if now_playing_success:
        print(f"Now Playing: {now_playing_data}")
    
    # Test user registration (optional, may fail if user already exists)
    test_user_data = {
        "email": f"test_user_{int(time.time())}@example.com",
        "password": "TestPass123!",
        "username": f"test_user_{int(time.time())}",
        "full_name": "Test User"
    }
    
    register_success, _ = tester.test_register(test_user_data)
    
    # Test login
    if register_success:
        login_success = tester.test_login(test_user_data["email"], test_user_data["password"])
    else:
        # Try with default credentials if registration fails
        login_success = tester.test_login("admin@example.com", "admin123")
    
    # Test user profile if login successful
    if login_success:
        profile_success, profile_data = tester.test_get_user_profile()
        if profile_success:
            print(f"User Profile: {profile_data}")
    
    # Print results
    print(f"\n📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    return 0 if tester.tests_passed > 0 else 1

if __name__ == "__main__":
    sys.exit(main())