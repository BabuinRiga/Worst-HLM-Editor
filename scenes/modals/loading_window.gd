extends ModalWindow

@onready var title_label: Label = $Panel/VPanel/Title/Label
@onready var load_label: Label = $Panel/VPanel/Content/VBox/HBoxLabels/LabelData
@onready var label_count: Label = $Panel/VPanel/Content/VBox/HBoxLabels/LabelCount
@onready var progress_bar: ProgressBar = $Panel/VPanel/Content/VBox/ProgressBar


func _ready() -> void:
	AppEvents.load_started.connect(_on_started)
	AppEvents.load_progress.connect(_on_progress)
	AppEvents.load_finished.connect(_on_finished)
	hide()


func _on_started(title: String) -> void:
	title_label.text = title
	label_count.text = ""
	progress_bar.value = 0.0
	show()

func _on_progress(current: int, total: int, label: String, show_count: bool = true) -> void:
	if not current and not total:
		progress_bar.value = 100.0
		progress_bar.show_percentage = false
	else:
		progress_bar.show_percentage = true
		progress_bar.value = float(current) / max(float(total), 1.0) * 100.0
		if show_count:
			label_count.text = "(%d/%d)" % [current, total]
	load_label.text = label

func _on_finished() -> void:
	hide()
