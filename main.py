from modules.factory import create_core_service_from_env


def main():
    core_service = create_core_service_from_env()
    core_service.run()


if __name__ == "__main__":
    main()
