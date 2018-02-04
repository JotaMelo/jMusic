import jwt
import time
import sys

def getKeyID():
    fileName = sys.argv[1].split("/")[-1]
    if fileName.startswith("AuthKey_"):
        keyID = fileName.split("_")[1].split(".")[0]
    else:
        print "Couldn't extract key ID from filename"
        keyID = raw_input("Insert key ID: ")
    return keyID

if __name__ == "__main__":
    if len(sys.argv) <= 1:
        print "Pass the .p8 file as the argument"
        sys.exit()

    keyID = getKeyID()
    teamID = raw_input("Insert team ID: ")
    privateKey = open(sys.argv[1]).read()
    
    headers = {"alg": "ES256", "kid": keyID}
    payload = {"iss": teamID, "iat": time.time(), "exp": time.time() + 7776000}
    token = jwt.encode(payload, privateKey, algorithm="ES256", headers=headers)

    print "JWT Token: " + token
    print "Expiration timestamp: " + str(int(payload["exp"]))