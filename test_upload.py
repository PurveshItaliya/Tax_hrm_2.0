import requests

url = "https://taxcrmtesting.taxfile.co.in/api/Master/EmpFileUploads"
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJBYWEiLCJHSUQiOiI3OWUyZTQ4OS02YzFjLTRjMTctYTBmNi0xNTdlYjVkZWVhZjAiLCJqdGkiOiI1Y2FlNDFiMS02YTcxLTQ0NDQtOTEyOC02YjA3MDlmN2M0NzAiLCJpZCI6IjM5MTk0MSIsImN1c3RpZCI6IlRBWTk2NyIsImZpcnN0bmFtZSI6IkFhYSIsImxhc3RuYW1lIjoiQmJiIiwiZW1haWwiOiIiLCJDb21wYW55SWQiOiIxMDkyIiwicm9sZSI6IlVzZXIiLCJVUm9sZSI6IlVzZXIiLCJsb2dpbnRpbWUiOiIyOC0wOS0yMDI2IDE2OjMxOjU4IiwiSVBBZGRyZXNzIjoiMTAzLjI1MS4xOS42MyIsImV4cCI6MTc5MzE4NTMxOCwiaXNzIjoiaHR0cDovL1RheGZpbGVDcm1HU1QuY29tIiwiYXVkIjoiaHR0cDovL1RheGZpbGVDcm1HU1QuY29tIn0.xqqZc9kAsLtTzAg69cH5JPaUX2smD79yRJGuSYuKjVA"

headers = {
    "Authorization": f"bearer {token}"
}

data = {
    "Category": "visit",
    "CompanyId": "1092",
    "Cguid": "2cff7aab-2fa7ffb6-be14dbcf",
    "EmpId": "391941"
}
files = {"Filename": ("test.jpg", open("test.jpg", "rb"), "image/jpeg")}
response = requests.post(url, headers=headers, data=data, files=files)
print("TEST 6 - EmpFileUploads ->", response.text)

# Let's try testing api/Master/CompanyFileupload
url = "https://taxcrmtesting.taxfile.co.in/api/Master/CompanyFileupload"
response = requests.post(url, headers=headers, data=data, files=files)
print("TEST 7 - CompanyFileupload ->", response.text)

url = "https://taxcrmtesting.taxfile.co.in/api/hrm/CreateUpdateVisitImage"
response = requests.post(url, headers=headers, data=data, files=files)
print("TEST 8 - hrm/CreateUpdateVisitImage ->", response.status_code, response.text)

url = "https://taxcrmtesting.taxfile.co.in/api/hrm/UploadVisitImage"
response = requests.post(url, headers=headers, data=data, files=files)
print("TEST 9 - hrm/UploadVisitImage ->", response.status_code, response.text)

url = "https://taxcrmtesting.taxfile.co.in/api/hrm/VisitFileUpload"
response = requests.post(url, headers=headers, data=data, files=files)
print("TEST 10 - hrm/VisitFileUpload ->", response.status_code, response.text)

