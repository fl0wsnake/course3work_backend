defmodule Course3.Utils do

  def string_map_to_atom_map(map),
    do: for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}

end
