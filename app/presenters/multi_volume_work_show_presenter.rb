class MultiVolumeWorkShowPresenter < HyraxShowPresenter
  include PlumAttributes

  def viewing_hint
    'multi-part'
  end
end
