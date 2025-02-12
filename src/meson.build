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
