sources = [
    'Application.vala',
    'UI' / 'HeaderBar.vala',
    'UI' / 'MainWindow.vala',
    'UI' / 'Dialogs' / 'RenameDialog.vala',
    'UI' / 'FileView' / 'FileView.vala',
    'UI' / 'FileView' / 'GridView' / 'GridCell.vala',
    'UI' / 'FileView' / 'GridView' / 'GridView.vala',
    'UI' / 'FileView' / 'ListView' / 'FileCell.vala',
    'UI' / 'FileView' / 'ListView' / 'ListView.vala',
    'UI' / 'SideBar' / 'SideBar.vala',
    'Model' / 'Files' / 'Directory.vala',
    'Model' / 'Files' / 'Document.vala',
    'Model' / 'Files' / 'FileBase.vala',
    'Model' / 'Files' / 'FileModel.vala',
    'Model' / 'Operations' / 'ConflictableOperation.vala',
    'Model' / 'Operations' / 'CopyOperation.vala',
    'Model' / 'Operations' / 'MoveOperation.vala',
    'Model' / 'Operations' / 'Operation.vala',
    'Model' / 'Operations' / 'OperationManager.vala',
    'Model' / 'Operations' / 'RenameOperation.vala',
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
