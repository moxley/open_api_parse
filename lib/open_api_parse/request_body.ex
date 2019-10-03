defmodule OpenApiParse.RequestBody do
  defmodule Content do
    defstruct content_type: nil,
              schema: nil
  end

  defstruct name: nil,
            path: nil,
            contents: [],
            description: nil,
            required: false
end
