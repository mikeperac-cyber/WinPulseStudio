using WinPulseStudio.Models;

namespace WinPulseStudio.Services;

public interface INavigator
{
    void ShowHome();
    void ShowAdvanced();
    void ShowHistory();
    void ShowGuide(GoalContext goal);
}
