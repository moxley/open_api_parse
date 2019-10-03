defmodule OpenApiParse do
  defdelegate parse_file(file), to: OpenApiParse.Parse
end
