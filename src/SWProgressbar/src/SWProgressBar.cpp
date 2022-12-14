//
// module SWProgressBarCext
//   constant CEXT_VERSION
//   methods:
//      show
//      hide
//      label=
//      cancelled?
//      set_position
//
//
//  https://learn.microsoft.com/en-us/windows/win32/controls/progress-bar-control-reference
//

#include "RubyUtils/RubyUtils.h"
#include <commctrl.h>
#include <Shellapi.h>
#include <errhandlingapi.h>
#include <strsafe.h>
#include <comdef.h>
#include <iostream>
//#include "resource.h"


// function prototypes
void StartWindowThread();
ATOM MyRegisterClass(HINSTANCE);
HWND InitInstance(HINSTANCE, int);
void CreateControls32(HWND);
DWORD WINAPI PbarWindowThread(LPVOID);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);


// Global Variables
HWND hWndDialog = NULL;     // Dialog Window
HWND hWndPrgBar;            // ProgressBar
HWND hWndButton;            // Cancel Button
HWND hWndLabel;             //Text Label
HINSTANCE hInstance;

#define MAX_LOADSTRING 200
WCHAR szWindowClass[MAX_LOADSTRING] = L"SW_PROGRESSBAR";
WCHAR szLabelText[MAX_LOADSTRING];
WCHAR szDefaultLabelText[MAX_LOADSTRING] = L"Thinking";

bool running = FALSE;       // Controls termination of the Dialog Thread
bool userCancelled = FALSE; // True if the user has clicked the Cancel bvutton


//
// Ruby method: show()
// 
// Creates and shows the progress bar dialog window
// 
VALUE show() {
    running = TRUE;         
    userCancelled = FALSE;
    StartWindowThread();
    return TRUE;
}

//
// Start a thread that will run the progress bar dialog window
//
void StartWindowThread()
{
    DWORD   dwThreadId;
    HANDLE  hThread;
    
    // Initialize Dialog Text Label
    wcscpy_s(szLabelText, szDefaultLabelText);

    // Create the thread 
    hThread = CreateThread(
        NULL,                   // default security attributes
        0,                      // use default stack size  
        PbarWindowThread,        // thread function name
        0,                      // argument to thread function 
        0,                      // use default creation flags 
        &dwThreadId);           // returns the thread identifier 

    // Check the return value for success.
    // If CreateThread fails, terminate execution. 
    // This will automatically clean up threads and memory. 
    if (hThread == NULL)
    {
        MessageBox(NULL, L"Create Thread Failed", L"Error", MB_OK);
    }
    //CloseHandle(hThread); // Not needed
}

//
// Thread that creates and services the progress bar dialog window
//   - This loop will run until the Ruby method hide() is called
//
DWORD WINAPI PbarWindowThread(LPVOID lpParam)
{
    hInstance = (HINSTANCE)GetModuleHandle(NULL);

    // Register window class on first invocaton    
    if (hWndDialog == NULL) MyRegisterClass(hInstance);

    // Create and Show the window
    hWndDialog = InitInstance(hInstance, SW_SHOWNORMAL);

    // If the Ruby code has already hidden the dialog
    if (!running) PostQuitMessage(0);

    // Main message loop:
    MSG msg;

    while (GetMessage(&msg, nullptr, 0, 0))
    {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
    }
    return 0; // Thread terminated
}


//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASS wc = {};

    wc.lpfnWndProc = WndProc;
    wc.cbWndExtra = NULL;
    wc.hInstance = hInstance; // GetModuleHandle(NULL);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.style = CS_SAVEBITS | CS_GLOBALCLASS;
    wc.lpszClassName = szWindowClass;

    ATOM result = RegisterClass(&wc);
    if (!result)
    {
       DWORD result = GetLastError();
       MessageBox(NULL, L"RegClass Failed", L"Error", MB_OK);
    }
    return result;
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: creates and shows the dialog window
//
//   returns the dialog window handle
//
HWND InitInstance(HINSTANCE hInstance, int nCmdShow)
{
    HWND hwindow = CreateWindowW(szWindowClass, nullptr, WS_DLGFRAME | WS_EX_TOPMOST,
        CW_USEDEFAULT, 0, 400, 160, nullptr, nullptr, hInstance, nullptr);

    if (hwindow)
    {

        ShowWindow(hwindow, nCmdShow);
        UpdateWindow(hwindow);
    }

    return hwindow;
}


//
// Create Progress Bar, Label Text, and Cancel Button
//   - Called from the Message loop WM_CREATE
//
void CreateControls32(HWND hwnd) {
    hWndPrgBar = CreateWindowExW(0, PROGRESS_CLASS, NULL,
        WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
        30, 30, 325, 25, hwnd, NULL, NULL, NULL);

    hWndButton = CreateWindowW(L"Button", L"Cancel",
        WS_CHILD | WS_VISIBLE,
        140, 70, 85, 25, hwnd, (HMENU)1, NULL, NULL);

    hWndLabel = CreateWindowW(L"STATIC", szLabelText,
        WS_VISIBLE | WS_CHILD | SS_LEFT,
        30, 0, 325, 20, hwnd, (HMENU)2, NULL, NULL);

    SendMessage(hWndPrgBar, PBM_SETBARCOLOR, 0, RGB(0, 95, 158));
    SendMessage(hWndPrgBar, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
    SendMessage(hWndPrgBar, PBM_SETSTEP, 2, 0);
}


//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_KEYDOWN:
    {
        int cChar = LOWORD(wParam);
        if (cChar == VK_ESCAPE) userCancelled = TRUE;
    }
    break;
    case WM_CREATE:
    {
        CreateControls32(hWnd);
    }
    break;
    case WM_COMMAND:
    {
        int wmId = LOWORD(wParam);
        switch (wmId)
        {
        case 1:
            userCancelled = TRUE;
            break;
        default:
            return DefWindowProc(hWnd, message, wParam, lParam);
        }
    }
    break;
    case WM_CTLCOLORSTATIC:
    {
        return (INT_PTR)CreateSolidBrush(RGB(255, 255, 255));
    }
    break;
    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        // TODO: Add any drawing code that uses hdc here...
        EndPaint(hWnd, &ps);
    }
    break;
    case WM_DESTROY:
    {
        //MessageBox(NULL, L"Closing", L"Error", MB_OK);
        PostQuitMessage(0);
    }
    break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}


//
// Ruby method: set_position()
//
// Sets the text position of the progress bar
// Value is 0.0 to 100.0
//
VALUE set_position(VALUE self, VALUE v_position)
{
    int  position = NUM2INT(v_position);
    //rb_raise(rb_eArgError, "Invalid position");

    SendMessage(hWndPrgBar, PBM_SETPOS, position, 0);
    return TRUE;
}

//
// Ruby method: set_label()
//
// Sets the text label of the progress bar
//
VALUE set_label(VALUE self, VALUE v_label)
{
    char* strptr;
    int strlen;
    VALUE str = StringValue(v_label);
    strptr = RSTRING_PTR(str); // may be null
    strlen = RSTRING_LEN(str); // may be null

    //int count = MultiByteToWideChar(CP_UTF8, 0, strptr, strlen, NULL, 0);
    //std::wstring wstr(count, 0);
    //MultiByteToWideChar(CP_UTF8, 0, strptr, strlen, &wstr[0], count);
    //SetWindowTextW(hWndLabel, wstr.c_str());

    int count = MultiByteToWideChar(CP_UTF8, 0, strptr, strlen, NULL, 0);
    if (count > (MAX_LOADSTRING / 2) - 1 ) count = (MAX_LOADSTRING / 2) - 1  ;
    MultiByteToWideChar(CP_UTF8, 0, strptr, strlen, szLabelText, count);

    // ensure the wide string is null terminated
    szLabelText[count] = 0;
    szLabelText[count+1] = 0;

    SetWindowTextW(hWndLabel, szLabelText);

    return TRUE;
}

//
// Ruby method: Cancelled?
// 
// returns true if the user has clicked the Cancel button 
//
VALUE cancelled()
{
    if (userCancelled) return Qtrue;
    return Qfalse;
}

//
// Ruby method: hide()
// 
// Closes the progress bar dialog window
// 
//  The progressbar dialog is created asynchronously and the function hide()
//  may be called before the dialog is created in which case a WM_CLOSE
//  would be ignored by the OS. To get around this, we use the the Global
//  Variable 'running' to force the thread to terminate when it reaches
//  the main message loop.
//
VALUE hide()
{
    SendMessage(hWndDialog, WM_CLOSE, 0, 0); // Tickle the message loop
    running = FALSE; // Force termination of the main message loop
    return TRUE;
}

VALUE ruby_platform() {
  return GetRubyInterface(RUBY_PLATFORM);
}

//
// Instantiate the SWProgressBarCext Ruby module
//
extern "C"
void Init_SWProgressBar()
{
  VALUE mSWProgressbar = rb_define_module("SWProgressBarCext");
  rb_define_const(mSWProgressbar, "CEXT_VERSION", GetRubyInterface("2.0.0"));
  rb_define_module_function(mSWProgressbar, "show", VALUEFUNC(show), 0);
  rb_define_module_function(mSWProgressbar, "hide", VALUEFUNC(hide), 0);
  rb_define_module_function(mSWProgressbar, "label=", VALUEFUNC(set_label), 1);
  rb_define_module_function(mSWProgressbar, "cancelled?", VALUEFUNC(cancelled), 0);
  rb_define_module_function(mSWProgressbar, "set_position", VALUEFUNC(set_position), 1);
}
