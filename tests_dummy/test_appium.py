import pytest

@pytest.mark.parametrize('i', range(300))
def test_appium_mock(i):
    # Dummy mock of appium driver
    app_element = "loaded"
    assert app_element == "loaded"
