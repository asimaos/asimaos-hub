# Asima UI: the shared design system for all Asima OS apps (QML module "Asima.Ui").
qt_add_library(asimaos_ui STATIC)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(asimaos_ui
    URI Asima.Ui
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Asima/Ui
    QML_FILES
        Theme.qml
        UiText.qml
        Icon.qml
        IconTile.qml
        AsimaMark.qml
        Card.qml
        StatTile.qml
        StatusPill.qml
        DButton.qml
        NavItem.qml
        Sidebar.qml
        DPage.qml
        DScrollBar.qml
        DProgressBar.qml
        StatusRing.qml
        StatusGlyph.qml
        Spinner.qml
        InfoBanner.qml
        ListRow.qml
        StepList.qml
        SegmentedTabs.qml
        DTextField.qml
        DSwitch.qml
        DropZone.qml
        ConfirmDialog.qml
        Toast.qml
        WizardRail.qml
        WizardPage.qml
        SelectCard.qml
        OptionList.qml
        DComboBox.qml
        PasswordField.qml
        DCheckBox.qml
        QuickToggle.qml
        DSlider.qml
        ChoiceChips.qml
        DiffView.qml
    RESOURCES
        assets/asimaos-mark.svg
        assets/apps/updater.svg
        assets/apps/maintenance.svg
        assets/apps/manager.svg
        assets/apps/gaming.svg
        assets/apps/dev.svg
        assets/apps/hub.svg
    SOURCES
        asimaosui.h asimaosui.cpp
        iconprovider.h iconprovider.cpp
)

target_include_directories(asimaos_ui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(asimaos_ui PUBLIC Qt6::Gui Qt6::Quick Qt6::QuickControls2 Qt6::Svg)
