# Lab VAL01 - API Validation and OpenAPI

## Objective
The objective of this lab is to generate an OpenAPI spec for an API, and execute acceptance tests against an API

## Outcomes
By the end of this lab, you will have:
* Used swaggo to generate OpenAPI specs for an API
* Created a test suite based on that spec
* Executed acceptance tests

## High-Level Steps
* Obtain the source code
* Generate OpenAPI spec
* Create bruno collection from OpenAPI spec
* Implement and execute tests

## Detailed Steps

### Generate OpenAPI Specs
1. Change directory into the lab01 directory:
```bash
cd ~/validation-labs/lab01
```
2. Review the main.go file. Notice the comments - this is a specific doc comment format used by the swaggo/swag tool, which we will use in a moment.
3. Run `go mod tidy` to install current dependencies and initialise go.sum
4. Install swaggo/swag:
```bash
go install github.com/swaggo/swag/cmd/swag@latest
```
5. Once the tool is installed, run `swag init` to generate the OpenAPI specs
6. Review the generated documentation @ docs/swagger.json

### Setup Bruno Collection
Bruno is an API test runner, similar in capabilities to Postman. We will use Bruno over postman as it does not require a postman cloud account, and works entirely locally.
1. Bruno is developed in JS, and can be installed easily via npm: `npm i -g @usebruno/cli`
2. Wait for the installation to complete, then use bruno to generate a 'collection' from the openapi spec we generated:
```bash
bru import --source docs/swagger.json -o bruno -n "Example Collection"
```
This will create a new directory, bruno, which contains several .bru files. We will need to edit these to make them do anything interesting.
3. Open 'Manage_Tasks (POST).bru', and amend the contents like so:
```
meta {
  name: Manage_Tasks (POST)
  type: http
  seq: 1
}

post {
  url: {{baseUrl}}/tasks
  auth: inherit
}

body {
  {
    "id": "ae3f1c",
    "title": "Task1",
    "description": "A sample task",
    "completed": false
  }
}

tests {
  test("should have created the task", function() {
    expect(res.body.id).to.equal("ae3f1c");
  });
}
```
4. amend the other files similarly
*`Manage_Tasks.bru`*:
```
meta {
  name: Manage_Tasks
  type: http
  seq: 2
}

get {
  url: {{baseUrl}}/tasks
  body: none
  auth: inherit
}

tests {
  test("should return items", function() {
    expect(res.body).to.be.an('object');
  });
}
```
*`Manage_Tasks (PUT).bru`*
```
meta {
  name: Manage_Tasks (POST)
  type: http
  seq: 3
}

put {
  url: {{baseUrl}}/tasks
  auth: inherit
}

body {
  {
    "id": "ae3f1c",
    "title": "Task1",
    "description": "A sample task",
    "completed": true
  }
}

tests {
  test("should have updated the task", function() {
    expect(res.body.completed).to.equal(true);
  });
}
```
*`Manage_Tasks (DELETE).bru`*
```
meta {
  name: Manage_Tasks (POST)
  type: http
  seq: 4
}

delete {
  url: {{baseUrl}}/tasks
  auth: inherit
}

body {
  {
    "id": "ae3f1c",
    "title": "Task1",
    "description": "A sample task",
    "completed": true
  }
}

tests {
  test("should have deleted the task", function() {
    expect(res.body).to.not.have.property("ae3f1c");
  });
}
```
5. Once you have made the changes, start the app and use bruno to execute the defined tests:
```bash
go run main.go &
cd bruno
bru run --env-var baseUrl=http://localhost:8080 --reporter-json results.json
```
