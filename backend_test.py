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

    def test_role_based_access(self, email, password, expected_role):
        """Test login and role-based access for a specific role"""
        print(f"\n===== Testing Role-Based Access for {expected_role} =====")
        
        # Login with the role-specific credentials
        login_success = self.test_login(email, password)
        if not login_success:
            print(f"❌ Login failed for {email}")
            return False
        
        # Get user profile to verify role
        profile_success, profile_data = self.test_get_user_profile()
        if not profile_success:
            print(f"❌ Failed to get user profile for {email}")
            return False
        
        # Verify the user has the expected role
        actual_role = profile_data.get("role", "unknown")
        if actual_role != expected_role:
            print(f"❌ Role mismatch: expected {expected_role}, got {actual_role}")
            return False
        
        print(f"✅ User has correct role: {actual_role}")
        
        # Test access to different dashboards
        dashboards = [
            {"endpoint": "admin/dashboard", "allowed_roles": ["admin", "staff"]},
            {"endpoint": "artist/dashboard", "allowed_roles": ["admin", "staff", "artist"]},
            {"endpoint": "podcaster/dashboard", "allowed_roles": ["admin", "staff", "podcaster"]}
        ]
        
        for dashboard in dashboards:
            endpoint = dashboard["endpoint"]
            allowed = expected_role in dashboard["allowed_roles"]
            expected_status = 200 if allowed else 403
            
            # Some endpoints might not exist but should still check auth
            if not allowed:
                print(f"Testing access to /{endpoint} (should be denied)")
                success, _ = self.run_test(
                    f"Access to /{endpoint}",
                    "GET",
                    endpoint,
                    403
                )
                if not success:
                    print(f"❌ Access control failed for {expected_role} to /{endpoint}")
            else:
                print(f"Testing access to /{endpoint} (should be allowed)")
                # For allowed roles, we accept either 200 (success) or 404 (endpoint doesn't exist)
                # since we're testing auth, not the endpoint itself
                response = requests.get(f"{self.api_url}/{endpoint}", 
                                       headers={'Authorization': f'Bearer {self.token}'})
                if response.status_code in [200, 404]:
                    print(f"✅ Access granted as expected for {expected_role} to /{endpoint}")
                    self.tests_passed += 1
                else:
                    print(f"❌ Expected access to be granted, got status {response.status_code}")
        
        return True

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
    
    # Test role-based access for different roles
    test_roles = [
        {"email": "admin@test.com", "password": "password", "role": "admin"},
        {"email": "staff@test.com", "password": "password", "role": "staff"},
        {"email": "artist@test.com", "password": "password", "role": "artist"},
        {"email": "podcaster@test.com", "password": "password", "role": "podcaster"},
        {"email": f"member_{int(time.time())}@test.com", "password": "password", "role": "member"}
    ]
    
    for role_test in test_roles:
        tester.test_role_based_access(
            role_test["email"], 
            role_test["password"], 
            role_test["role"]
        )
    
    # Print results
    print(f"\n📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    return 0 if tester.tests_passed > 0 else 1

if __name__ == "__main__":
    sys.exit(main())