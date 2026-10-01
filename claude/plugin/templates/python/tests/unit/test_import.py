import project_name


class TestPackage:
    def test_package_imports(self) -> None:
        assert project_name.__all__ == []
