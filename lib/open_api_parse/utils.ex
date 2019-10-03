defmodule OpenApiParse.Utils do
  @doc """
  Applies map values into a struct, converting keys from
  strings to atoms if necessary.

  Like `Kernel.struct/2`, but converts from string keys.
  """
  def struct_from_map(struct, map) when is_atom(struct) do
    struct_from_map(struct.__struct__(), map)
  end

  def struct_from_map(%_{} = struct, map) do
    keys = struct |> Map.from_struct() |> Map.keys()

    Enum.reduce(keys, struct, fn key, struct ->
      case map_get(map, key) do
        {_, value} -> Map.put(struct, key, value)
        _ -> struct
      end
    end)
  end

  def to_module_name(string) do
    string
    |> String.replace(~r/\s+/, "_")
    |> String.downcase()
    |> Macro.camelize()
  end

  def underscore(string) do
    string
    |> Macro.underscore()
    |> String.replace(~r/[\[\]]/, " ")
    |> String.trim()
    |> String.replace(~r/[\s\-]+/, "_")
  end

  def cast_atom_enum(atom, enum) when is_atom(atom) do
    if atom in enum, do: atom, else: nil
  end

  def cast_atom_enum(string, enum) do
    lookup = enum |> Enum.map(fn atom -> {to_string(atom), atom} end) |> Map.new()
    Map.get(lookup, string)
  end

  def group_params(params) do
    Enum.reduce(params, %{}, fn {key, value}, params ->
      if String.contains?(key, "[") do
        Map.put(params, key, value)
      else
        Map.put(params, key, value)
      end
    end)
  end

  ## Private functions

  defp map_get(map, atom_key) when is_atom(atom_key) do
    with %{^atom_key => value} <- map do
      {atom_key, value}
    else
      _ -> map_get(map, to_string(atom_key))
    end
  end

  defp map_get(map, string_key) when is_binary(string_key) do
    case map do
      %{^string_key => value} -> {string_key, value}
      _ -> nil
    end
  end
end
