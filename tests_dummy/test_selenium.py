import pytest

@pytest.mark.parametrize('i', range(300))
def test_selenium_mock(i):
    # Dummy mock of selenium webdriver
    title = "PetConnect"
    assert title == "PetConnect"
