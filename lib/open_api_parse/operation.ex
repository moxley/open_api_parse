defmodule OpenApiParse.Operation do
  alias OpenApiParse.Utils

  defstruct action: nil,
            description: nil,
            operationId: nil,
            parameters: [],
            path: nil,
            requestBody: nil,
            responses: [],
            security: [],
            summary: nil,
            tags: []

  @actions [:get, :post, :patch, :put, :delete, :options, :head]

  def cast_action(encoded_action) do
    Utils.cast_atom_enum(encoded_action, @actions)
  end
end
