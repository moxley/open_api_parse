defmodule OpenApiParse.Info do
  defstruct description: nil,
            version: nil,
            title: nil,
            termsOfService: nil,
            contact: %{},
            license: %{}
end
