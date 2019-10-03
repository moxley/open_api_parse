defmodule OpenApiParse.Parameter do
  defstruct name: nil,
            in: nil,
            description: nil,
            required: false,
            explode: false,
            schema: nil
end
