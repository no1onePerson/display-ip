#!/usr/bin/env python3
"""Generate a deterministic Xcode project without external dependencies."""
import hashlib, json, pathlib, plistlib
root = pathlib.Path(__file__).resolve().parents[1] / 'macOS'
objects = {}
def uid(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def add(object_name, isa, **fields):
    key = uid(object_name); objects[key] = {'isa': isa, **fields}; return key
def quote(v):
    if isinstance(v, dict): return '{\n' + '\n'.join(f'{json.dumps(str(k))} = {quote(x)};' for k,x in v.items()) + '\n}'
    if isinstance(v, list): return '(' + ',\n'.join(quote(x) for x in v) + ')'
    return json.dumps(str(v))
main_children=[]
products=[]
package = add('package', 'XCLocalSwiftPackageReference', relativePath='.')
core = add('core-product', 'XCSwiftPackageProductDependency', package=package, productName='PrismCore')
base = {'SWIFT_VERSION':'6.0','SWIFT_STRICT_CONCURRENCY':'complete','MACOSX_DEPLOYMENT_TARGET':'14.0','SDKROOT':'macosx','CLANG_ENABLE_MODULES':'YES','ENABLE_HARDENED_RUNTIME':'YES','CODE_SIGN_STYLE':'Automatic'}
def configs(name, extra):
    entries=[]
    for mode in ['Debug','Release']:
        settings={**extra,'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym'}
        if mode=='Debug': settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG'
        entries.append(add(name+mode,'XCBuildConfiguration',buildSettings=settings,name=mode))
    return add(name+'configs','XCConfigurationList',buildConfigurations=entries,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
project_configs=configs('project',base)
(root/'Configuration').mkdir(exist_ok=True)
for target, dirs, product, bundle, extension in [('IPPrism',['Sources','Shared'],'IpBan.app','com.displayip.app',False),('IPPrismWidget',['Widget','Shared'],'IPPrismWidget.appex','com.displayip.app.widget',True)]:
    sources=[]
    for directory in dirs:
        for path in sorted((root/directory).glob('*.swift')):
            name=str(path.relative_to(root)); ref=add('file:'+name,'PBXFileReference',lastKnownFileType='sourcecode.swift',path=name,sourceTree='<group>')
            if ref not in main_children: main_children.append(ref)
            sources.append(add(target+name,'PBXBuildFile',fileRef=ref))
    source_phase=add(target+'sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=sources,runOnlyForDeploymentPostprocessing=0)
    framework_files=[]
    if not extension: framework_files.append(add('core-build','PBXBuildFile',productRef=core))
    frameworks=add(target+'frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=framework_files,runOnlyForDeploymentPostprocessing=0)
    resources=[]
    if not extension:
        assets=add('assets','PBXFileReference',lastKnownFileType='folder.assetcatalog',path='Resources/Assets.xcassets',sourceTree='<group>'); main_children.append(assets)
        resources.append(add('assets-build','PBXBuildFile',fileRef=assets))
    resource_phase=add(target+'resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=resources,runOnlyForDeploymentPostprocessing=0)
    product_ref=add(target+'product','PBXFileReference',explicitFileType='wrapper.app-extension' if extension else 'wrapper.application',includeInIndex=0,path=product,sourceTree='BUILT_PRODUCTS_DIR'); products.append(product_ref)
    info={'CFBundleDisplayName':'IpBan','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'XPC!' if extension else 'APPL','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','LSMinimumSystemVersion':'$(MACOSX_DEPLOYMENT_TARGET)'}
    if extension: info['NSExtension']={'NSExtensionPointIdentifier':'com.apple.widgetkit-extension'}
    else: info.update(CFBundleURLTypes=[{'CFBundleURLName':'IpBan','CFBundleURLSchemes':['ipprism']}],LSUIElement=True,LSApplicationCategoryType='public.app-category.utilities',CFBundleIconFile='AppIcon')
    entitlements={'com.apple.security.app-sandbox':True,'com.apple.security.application-groups':['group.com.displayip.shared']}
    if not extension: entitlements.update({'com.apple.security.network.client':True,'com.apple.security.files.user-selected.read-write':True})
    for suffix, data in [('plist',info),('entitlements',entitlements)]:
        (root/'Configuration'/f'{target}.{suffix}').write_bytes(plistlib.dumps(data))
    settings={'PRODUCT_BUNDLE_IDENTIFIER':bundle,'PRODUCT_NAME':'IPPrismWidget' if extension else 'IpBan','INFOPLIST_FILE':f'Configuration/{target}.plist','CODE_SIGN_ENTITLEMENTS':f'Configuration/{target}.entitlements','MARKETING_VERSION':'0.4.0','CURRENT_PROJECT_VERSION':'4','SKIP_INSTALL':'YES' if extension else 'NO','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/../Frameworks @executable_path/../../../../Frameworks','ENABLE_APP_SANDBOX':'YES','GENERATE_INFOPLIST_FILE':'NO'}
    if extension: settings['APPLICATION_EXTENSION_API_ONLY']='YES'
    else: settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
    phases=[source_phase,frameworks,resource_phase]
    dependencies=[]
    if not extension:
        embedfile=add('widget-embed-file','PBXBuildFile',fileRef=uid('IPPrismWidgetproduct'),settings={'ATTRIBUTES':['RemoveHeadersOnCopy']})
        phases.append(add('widget-embed','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=13,files=[embedfile],name='Embed App Extensions',runOnlyForDeploymentPostprocessing=0))
        proxy=add('widget-proxy','PBXContainerItemProxy',containerPortal=uid('project'),proxyType=1,remoteGlobalIDString=uid('IPPrismWidget'),remoteInfo='IPPrismWidget')
        dependencies.append(add('widget-dependency','PBXTargetDependency',target=uid('IPPrismWidget'),targetProxy=proxy))
    fields=dict(buildConfigurationList=configs(target,settings),buildPhases=phases,buildRules=[],dependencies=dependencies,name=target,productName=target,productReference=product_ref,productType='com.apple.product-type.app-extension' if extension else 'com.apple.product-type.application')
    if not extension: fields['packageProductDependencies']=[core]
    add(target,'PBXNativeTarget',**fields)
product_group=add('products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main=add('main','PBXGroup',children=main_children+[product_group],sourceTree='<group>')
add('project','PBXProject',attributes={'LastUpgradeCheck':'1600'},buildConfigurationList=project_configs,compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=main,productRefGroup=product_group,projectDirPath='',projectRoot='',packageReferences=[package],targets=[uid('IPPrism'),uid('IPPrismWidget')])
project=root/'IPPrism.xcodeproj'; project.mkdir(exist_ok=True)
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n'+quote({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':uid('project')})+'\n')
schemes=project/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
(schemes/'IPPrism.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('IPPrism')}" BuildableName="IpBan.app" BlueprintName="IPPrism" ReferencedContainer="container:IPPrism.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid('IPPrism')}" BuildableName="IpBan.app" BlueprintName="IPPrism" ReferencedContainer="container:IPPrism.xcodeproj"/></BuildableProductRunnable></LaunchAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''')
print(project)
