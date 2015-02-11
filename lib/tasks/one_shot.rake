namespace :one_shot do
  desc "Generate reference image for road tile graphics."
  task :generate_road_tile_reference do
    primitives_base = Magick::Image.read("#{Rails.root}/lib/tasks/assets/road_tile_primitives.png")[0]
    primitives = (0..5).to_a.map do |i|
      primitives_base.crop(0, i * 34, 32, 34)
    end

    out = Magick::Image.new(32, 34 * 64)
    out.alpha(Magick::TransparentAlphaChannel)

    0.upto(63) do |i|
      # Generate the binary string for i
      key = i.to_s(2)

      # Pad the binary string with zeros in the front
      while key.size < 6
        key = '0' + key
      end

      puts key

      key.chars.to_a.reverse.each_with_index do |bool, j|
        if bool == '1'
          out.composite!(primitives[j], 0, 34 * i, Magick::OverCompositeOp)
        end
      end
    end

    out.write("#{Rails.root}/road_tile_reference.png")
  end
end
