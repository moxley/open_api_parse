defmodule OpenApiParse.ParseTest do
  use ExUnit.Case, async: true

  alias OpenApiParse.{
    Contact,
    Info,
    License,
    MediaType,
    Operation,
    Parameter,
    Parse,
    Reference,
    RequestBody,
    Response,
    Schema
  }

  @file_path "test/fixtures/swagger_petstore_openapi_3.yaml"

  describe "parse_file/1" do
    test "parsing info" do
      {:ok, doc} = Parse.parse_file(@file_path)

      assert doc.info == %Info{
               contact: %Contact{email: "apiteam@swagger.io"},
               description:
                 "This is a sample server Petstore server.  You can find out more about Swagger at [http://swagger.io](http://swagger.io) or on [irc.freenode.net, #swagger](http://swagger.io/irc/).  For this sample, you can use the api key `special-key` to test the authorization filters.",
               license: %License{
                 name: "Apache 2.0",
                 url: "http://www.apache.org/licenses/LICENSE-2.0.html"
               },
               termsOfService: "http://swagger.io/terms/",
               title: "Swagger Petstore",
               version: "1.0.0"
             }
    end

    test "parsing operations" do
      {:ok, doc} = Parse.parse_file(@file_path)
      [op | _] = doc.operations

      assert op == %Operation{
               action: :post,
               description: "",
               operationId: "addPet",
               path: "/pet",
               requestBody: %Reference{path: "#/components/requestBodies/Pet"},
               responses: [%Response{description: "Invalid input", http_status: "405"}],
               security: [%{"petstore_auth" => ["write:pets", "read:pets"]}],
               summary: "Add a new pet to the store",
               tags: ["pet"]
             }

      op = Enum.find(doc.operations, fn op -> op.operationId == "updatePetWithForm" end)
      assert %RequestBody{} = op.requestBody
    end

    test "parsing operation parameters" do
      {:ok, doc} = Parse.parse_file(@file_path)
      op = Enum.find(doc.operations, fn op -> op.operationId == "findPetsByTags" end)

      assert op == %OpenApiParse.Operation{
               requestBody: nil,
               action: :get,
               description:
                 "Multiple tags can be provided with comma separated strings. Use tag1, tag2, tag3 for testing.",
               operationId: "findPetsByTags",
               path: "/pet/findByTags",
               parameters: [
                 %Parameter{
                   description: "Tags to filter by",
                   explode: true,
                   in: "query",
                   name: "tags",
                   required: true,
                   schema: %Schema{
                     items: %{"type" => "string"},
                     type: "array"
                   }
                 }
               ],
               responses: [
                 %OpenApiParse.Response{
                   description: "successful operation",
                   http_status: "200"
                 },
                 %OpenApiParse.Response{description: "Invalid tag value", http_status: "400"}
               ],
               security: [%{"petstore_auth" => ["write:pets", "read:pets"]}],
               summary: "Finds Pets by tags",
               tags: ["pet"]
             }
    end

    test "parsing components:schemas" do
      {:ok, doc} = Parse.parse_file(@file_path)
      assert schema = Enum.find(doc.components, &(&1.path == "#/components/schemas/Pet"))

      assert %Schema{} = schema

      assert schema == %Schema{
               name: "Pet",
               path: "#/components/schemas/Pet",
               properties: %{
                 category: %Reference{path: "#/components/schemas/Category"},
                 id: %Schema{
                   format: "int64",
                   type: "integer"
                 },
                 name: %Schema{
                   example: "doggie",
                   type: "string"
                 },
                 photoUrls: %Schema{
                   items: %{"type" => "string"},
                   type: "array",
                   xml: %{"name" => "photoUrl", "wrapped" => true}
                 },
                 status: %Schema{
                   description: "pet status in the store",
                   enum: ["available", "pending", "sold"],
                   type: "string"
                 },
                 tags: %Schema{
                   items: %{"$ref" => "#/components/schemas/Tag"},
                   type: "array",
                   xml: %{"name" => "tag", "wrapped" => true}
                 }
               },
               required: ["name", "photoUrls"],
               type: "object",
               xml: %{"name" => "Pet"}
             }
    end

    test "parsing components:requestBodies" do
      {:ok, doc} = Parse.parse_file(@file_path)

      assert rb =
               Enum.find(doc.components, fn comp ->
                 comp.path == "#/components/requestBodies/Pet"
               end)

      assert %RequestBody{
               name: "Pet",
               description: "Pet object that needs to be added to the store",
               path: "#/components/requestBodies/Pet",
               required: true,
               contents: [media | _]
             } = rb

      assert media == %MediaType{
               content_type: "application/json",
               schema: %Reference{path: "#/components/schemas/Pet"}
             }
    end
  end
end
