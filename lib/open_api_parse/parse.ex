defmodule OpenApiParse.Parse do
  alias OpenApiParse.Utils

  alias OpenApiParse.{
    Contact,
    Document,
    Info,
    MediaType,
    License,
    Operation,
    Parameter,
    Reference,
    RequestBody,
    Response,
    Schema
  }

  def parse_file(file_path) do
    with {:ok, source_doc} <- YamlElixir.read_from_file(file_path) do
      # ["components", "externalDocs", "info", "openapi", "paths", "servers", "tags"]
      # IO.inspect(source_doc["components"], label: "components")

      document =
        %Document{}
        |> parse_info(source_doc)
        |> parse_operations(source_doc)
        |> parse_components(source_doc)

      {:ok, document}
    end
  end

  ## Private functions

  defp parse_info(%Document{} = document, %{"info" => source_info}) do
    info = Utils.struct_from_map(Info, source_info)

    contact = Utils.struct_from_map(Contact, info.contact)
    license = Utils.struct_from_map(License, info.license)
    info = %{info | contact: contact, license: license}

    %{document | info: info}
  end

  defp parse_operations(%Document{} = document, %{"paths" => paths}) do
    operations =
      Enum.flat_map(paths, fn {path, actions} ->
        for {action_name, source_operation} <- actions do
          operation = Utils.struct_from_map(Operation, source_operation)
          action = Operation.cast_action(action_name)

          %{operation | path: path, action: action}
          |> parse_responses(source_operation)
          |> parse_parameters(source_operation)
          |> parse_request_body(source_operation)
        end
      end)

    %{document | operations: operations}
  end

  defp parse_operations(%Document{} = document, %{}) do
    document
  end

  defp parse_responses(%Operation{} = operation, %{"responses" => responses}) do
    responses =
      for {http_status, resp} <- responses do
        response = Utils.struct_from_map(Response, resp)
        %{response | http_status: http_status}
      end

    %{operation | responses: responses}
  end

  defp parse_responses(%Operation{} = operation, %{}) do
    operation
  end

  defp parse_request_body(%Operation{} = operation, %{"requestBody" => %{"$ref" => path}}) do
    request_body = %Reference{path: path}
    %{operation | requestBody: request_body}
  end

  defp parse_request_body(%Operation{} = operation, %{"requestBody" => source_request_body}) do
    request_body = Utils.struct_from_map(RequestBody, source_request_body)
    contents = parse_request_body_media_types(source_request_body["content"])
    request_body = %{request_body | contents: contents}
    %{operation | requestBody: request_body}
  end

  defp parse_request_body(%Operation{} = operation, _source_operation) do
    operation
  end

  defp parse_parameters(%Operation{} = operation, %{"parameters" => source_parameters})
       when is_list(source_parameters) do
    parameters =
      Enum.map(source_parameters, fn source_param ->
        param = Utils.struct_from_map(Parameter, source_param)
        schema = parse_schema_or_reference(param.schema)
        %{param | schema: schema}
      end)

    %{operation | parameters: parameters}
  end

  defp parse_parameters(%Operation{} = operation, _source_operation) do
    operation
  end

  defp parse_components(%Document{} = document, source_document) do
    components =
      []
      |> parse_schemas(source_document["components"])
      |> parse_request_bodies(source_document["components"])

    %{document | components: components}
  end

  defp parse_schemas(components, %{"schemas" => source_schemas}) do
    schemas =
      for {name, source_schema} <- source_schemas do
        schema = Utils.struct_from_map(%Schema{}, source_schema)
        path = "#/components/schemas/#{name}"

        properties = parse_properties(schema.properties)
        %{schema | name: name, path: path, properties: properties}
      end

    schemas ++ components
  end

  defp parse_request_bodies(components, %{"requestBodies" => source_request_bodies}) do
    requestBodies =
      for {name, source_rb} <- source_request_bodies do
        request_body = Utils.struct_from_map(%RequestBody{}, source_rb)
        path = "#/components/requestBodies/#{name}"
        contents = parse_request_body_media_types(source_rb["content"])
        %{request_body | name: name, path: path, contents: contents}
      end

    requestBodies ++ components
  end

  defp parse_properties(nil), do: %{}

  defp parse_properties(properties) do
    for {key, value} <- properties, into: %{} do
      # Note: calling String.to_atom(), which should normally be avoided.
      # Do not allow unauthorized access to this module
      key =
        case key do
          _ when is_binary(key) -> String.to_atom(key)
          _ when is_atom(key) -> key
        end

      schema = parse_schema_or_reference(value)

      {key, schema}
    end
  end

  defp parse_request_body_media_types(source_media_types) do
    for {content_type, source_media_type} <- source_media_types do
      media_type = Utils.struct_from_map(%MediaType{}, source_media_type)
      schema = parse_schema_or_reference(source_media_type["schema"])
      %{media_type | schema: schema, content_type: content_type}
    end
  end

  defp parse_schema_or_reference(%{"$ref" => path}) do
    %Reference{path: path}
  end

  defp parse_schema_or_reference(source_schema) when is_map(source_schema) do
    Utils.struct_from_map(%Schema{}, source_schema)
  end

  defp parse_schema_or_reference(nil) do
    nil
  end
end
