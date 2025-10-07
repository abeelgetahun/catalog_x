import os
from pathlib import Path

def create_folder_structure():
    #  folder structure
    structure = {
        'lib': {
            'app': ['app.dart', 'routes.dart', 'theme.dart'],
            'core': {
                'constants': ['api_constants.dart'],
                'errors': ['failures.dart'],
                'network': ['network_info.dart'],
                'utils': ['debouncer.dart', 'extensions.dart'],
                'widgets': ['error_widget.dart', 'loading_widget.dart', 'shimmer_widget.dart']
            },
            'features': {
                'catalog': {
                    'data': {
                        'datasources': ['product_local_datasource.dart', 'product_remote_datasource.dart'],
                        'models': ['product_model.dart'],
                        'repositories': ['product_repository_impl.dart']
                    },
                    'domain': {
                        'entities': ['product.dart'],
                        'repositories': ['product_repository.dart']
                    },
                    'presentation': {
                        'blocs': ['catalog_bloc.dart', 'catalog_event.dart', 'catalog_state.dart'],
                        'pages': ['catalog_page.dart'],
                        'widgets': ['category_chips.dart', 'product_card.dart', 'search_bar.dart']
                    }
                },
                'product_detail': {
                    'data': {
                        'repositories': ['product_detail_repository_impl.dart']
                    },
                    'domain': {
                        'repositories': ['product_detail_repository.dart']
                    },
                    'presentation': {
                        'blocs': ['product_detail_bloc.dart', 'product_detail_event.dart', 'product_detail_state.dart'],
                        'pages': ['product_detail_page.dart'],
                        'widgets': ['product_detail_content.dart']
                    }
                }
            },
            'injection_container.dart': None,
            'main.dart': None
        },
        'test': {
            'features': {
                'catalog': {
                    'data': [],
                    'presentation': {
                        'blocs': ['catalog_bloc_test.dart'],
                        'pages': ['catalog_page_test.dart']
                    }
                },
                'product_detail': {}
            },
            'helpers': ['test_helper.dart']
        },
        'assets': ['products.json'],
        'pubspec.yaml': None,
        'README.md': None
    }

    def create_structure(base_path, structure_dict):
        for item, content in structure_dict.items():
            item_path = os.path.join(base_path, item)
            
            if content is None:  # file
                if not os.path.exists(item_path):
                    Path(item_path).touch()
                    print(f"Created file: {item_path}")
                else:
                    print(f"File already exists: {item_path}")
            elif isinstance(content, list):  # folder with files
                if not os.path.exists(item_path):
                    os.makedirs(item_path)
                    print(f"Created folder: {item_path}")
                else:
                    print(f"Folder already exists: {item_path}")
                
                for file in content:
                    file_path = os.path.join(item_path, file)
                    if not os.path.exists(file_path):
                        Path(file_path).touch()
                        print(f"Created file: {file_path}")
                    else:
                        print(f"File already exists: {file_path}")
            elif isinstance(content, dict):  # It's a nested structure
                if not os.path.exists(item_path):
                    os.makedirs(item_path)
                    print(f"Created folder: {item_path}")
                else:
                    print(f"Folder already exists: {item_path}")
                create_structure(item_path, content)

    # Start creating  from current directory
    current_dir = os.getcwd()
    print("Creating folder structure...")
    create_structure(current_dir, structure)
    print("\nFolder structure creation completed!")

    # Check if lib folder already existed
    lib_path = os.path.join(current_dir, 'lib')
    if os.path.exists(lib_path):
        print("\nNote: lib folder already existed - only missing files and folders were added")
    else:
        print("\nNote: lib folder was created as part of the structure")

if __name__ == "__main__":
    create_folder_structure()