defmodule OpenApiParse.Document do
  defstruct info: nil,
            operations: [],
            components: []

  def component_lookup(%__MODULE__{components: components}) do
    components
    |> Enum.map(fn comp -> {comp.path, comp} end)
    |> Map.new()
  end
end
