sources = [
    'Application.vala',
    'UI' / 'MainView.vala',
    'UI' / 'MainWindow.vala',
    'UI' / 'ListView' / 'FileRow.vala',
    'UI' / 'ListView' / 'ListView.vala',
    'Model' / 'Files' / 'Directory.vala',
    'Model' / 'Files' / 'Document.vala',
    'Model' / 'Files' / 'FileBase.vala',
    'Model' / 'Files' / 'FileModel.vala',
    'Model' / 'Operations' / 'ConflictableOperation.vala',
    'Model' / 'Operations' / 'CopyOperation.vala',
    'Model' / 'Operations' / 'MoveOperation.vala',
    'Model' / 'Operations' / 'Operation.vala',
    'Model' / 'Operations' / 'OperationManager.vala',
    'Model' / 'Operations' / 'TrashOperation.vala',
]

# Create a new executable, list the files we want to compile, and install
executable(
    meson.project_name(),
    config_file,
    gresource,
    sources,
    dependencies: deps,
    install: true
)
