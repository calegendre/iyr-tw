import requests
import sys
import os
from datetime import datetime

class ItsYourRadioAPITester:
    def __init__(self, base_url="https://1a906595-8810-4dd1-a53b-8279808fe840.preview.emergentagent.com/api"):
        self.base_url = base_url
        self.token = None
        self.tests_run = 0
        self.tests_passed = 0
        self.user_data = None

    def run_test(self, name, method, endpoint, expected_status, data=None, headers=None):
        """Run a single API test"""
        url = f"{self.base_url}/{endpoint}"
        
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
                    return success, response.json()
                except:
                    return success, {}
            else:
                print(f"❌ Failed - Expected {expected_status}, got {response.status_code}")
                try:
                    print(f"Response: {response.json()}")
                except:
                    print(f"Response: {response.text}")
                return False, {}

        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False, {}

    def test_login(self, email, password):
        """Test login and get token"""
        print(f"\n🔑 Testing login with {email}...")
        success, response = self.run_test(
            "Login",
            "POST",
            "auth/login",
            200,
            data={"email": email, "password": password}
        )
        
        if success and 'access_token' in response:
            self.token = response['access_token']
            self.user_data = response.get('user', {})
            print(f"✅ Login successful - User role: {self.user_data.get('role', 'unknown')}")
            return True
        
        print("❌ Login failed")
        return False

    def test_me_endpoint(self):
        """Test the /me endpoint to get current user info"""
        if not self.token:
            print("❌ Cannot test /me endpoint - No authentication token")
            return False
            
        success, response = self.run_test(
            "Get Current User",
            "GET",
            "users/me",
            200
        )
        
        if success:
            print(f"✅ User data retrieved: {response}")
            return True
        return False

def main():
    # Setup
    tester = ItsYourRadioAPITester()
    
    # Test special test accounts
    test_accounts = [
        {"email": "admin@test.com", "password": "password", "expected_role": "admin"},
        {"email": "staff@test.com", "password": "password", "expected_role": "staff"},
        {"email": "artist@test.com", "password": "password", "expected_role": "artist"},
        {"email": "podcaster@test.com", "password": "password", "expected_role": "podcaster"},
        {"email": "regular@test.com", "password": "password", "expected_role": "member"}
    ]
    
    for account in test_accounts:
        if tester.test_login(account["email"], account["password"]):
            # Verify the role is correct
            actual_role = tester.user_data.get('role')
            if actual_role == account["expected_role"]:
                print(f"✅ Role verification passed: {actual_role}")
            else:
                print(f"❌ Role verification failed: Expected {account['expected_role']}, got {actual_role}")
                
            # Test the /me endpoint
            tester.test_me_endpoint()
        else:
            print(f"❌ Could not test {account['email']} - Login failed")
        
        # Reset token between tests
        tester.token = None
        tester.user_data = None
    
    # Print results
    print(f"\n📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    return 0 if tester.tests_passed == tester.tests_run else 1

if __name__ == "__main__":
    sys.exit(main())