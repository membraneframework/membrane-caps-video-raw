defmodule Membrane.Caps.Video.Raw do
  @moduledoc """
  This module provides caps struct for raw video frames.
  """
  require Integer

  @typedoc """
  Width of single frame in pixels.
  """
  @type width_t :: pos_integer()

  @typedoc """
  Height of single frame in pixels.
  """
  @type height_t :: pos_integer()

  @typedoc """
  Number of frames per second. To avoid using floating point numbers,
  it is described by 2 integers number of frames per timeframe in seconds.

  For example, NTSC's framerate of ~29.97 fps is represented by `{30_000, 1001}`
  """
  @type framerate_t :: {frames :: non_neg_integer, seconds :: pos_integer}

  @typedoc """
  Format used to encode color of each pixel in each video frame.
  """
  @type format_t :: :I420 | :I422 | :I444 | :RGB | :BGRA | :RGBA | :NV12 | :NV21 | :YV12 | :AYUV

  @typedoc """
  Determines, whether buffers are aligned i.e. each buffer contains one frame.
  """
  @type aligned_t :: boolean()

  @type t :: %__MODULE__{
          width: width_t(),
          height: height_t(),
          framerate: framerate_t(),
          format: format_t(),
          aligned: aligned_t()
        }

  @enforce_keys [:width, :height, :framerate, :format, :aligned]
  defstruct @enforce_keys

  @doc """
  Simple wrapper over `frame_size/3`. Returns the size of raw video frame
  in bytes for the given caps.
  """
  @spec frame_size(t()) :: Bunch.Type.try_t(pos_integer)
  def frame_size(%__MODULE__{format: format, width: width, height: height}) do
    frame_size(format, width, height)
  end

  @doc """
  Returns the size of raw video frame in bytes (without padding).

  It may result in error when dimensions don't fulfill requirements for the given format
  (e.g. I420 requires both dimensions to be divisible by 2).
  """
  @spec frame_size(Raw.format_t(), Raw.width_t(), Raw.height()) :: Bunch.Type.try_t(pos_integer)
  def frame_size(format, width, height)
      when format in [:I420, :YV12, :NV12, :NV21] and Integer.is_even(width) and
             Integer.is_even(height) do
    # Subsampling by 2 in both dimensions
    # Y = width * height
    # V = U = (width / 2) * (height / 2)
    {:ok, div(width * height * 3, 2)}
  end

  def frame_size(:I422, width, height) when Integer.is_even(width) do
    # Subsampling by 2 in horizontal dimension
    # Y = width * height
    # V = U = (width / 2) * height
    {:ok, width * height * 2}
  end

  def frame_size(format, width, height) when format in [:I444, :RGB] do
    # No subsampling
    {:ok, width * height * 3}
  end

  def frame_size(format, width, height) when format in [:AYUV, :RGBA, :BGRA] do
    # No subsampling and added alpha channel
    {:ok, width * height * 4}
  end

  def frame_size(_, _, _) do
    {:error, :invalid_dims}
  end
end
