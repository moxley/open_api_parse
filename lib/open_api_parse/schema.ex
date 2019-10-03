defmodule OpenApiParse.Schema do
  defstruct name: nil,
            properties: nil,
            type: nil,
            items: nil,
            xml: nil,
            format: nil,
            description: nil,
            required: [],
            "$ref": nil,
            example: nil,
            enum: nil,
            path: nil
end
