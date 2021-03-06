// **********************************************************************
//
// Copyright (c) 2003-2018 ZeroC, Inc. All rights reserved.
//
// This copy of Ice is licensed to you under the terms described in the
// ICE_LICENSE file included in this distribution.
//
// **********************************************************************

using Test;

namespace Ice
{
    namespace operations
    {
        namespace AMD
        {
            namespace tie
            {
                public class Server : TestHelper
                {
                    public override void run(string[] args)
                    {
                        Ice.Properties properties = createTestProperties(ref args);
                        //
                        // Its possible to have batch oneway requests dispatched
                        // after the adapter is deactivated due to thread
                        // scheduling so we supress this warning.
                        //
                        properties.setProperty("Ice.Warn.Dispatch", "0");
                        //
                        // We don't want connection warnings because of the timeout test.
                        //
                        properties.setProperty("Ice.Warn.Connections", "0");
                        properties.setProperty("Ice.Package.Test", "Ice.operations.AMD");
                        using (var communicator = initialize(properties))
                        {
                            communicator.getProperties().setProperty("TestAdapter.Endpoints", getTestEndpoint(0));
                            Ice.ObjectAdapter adapter = communicator.createObjectAdapter("TestAdapter");
                            adapter.add(new MyDerivedClassI(), Ice.Util.stringToIdentity("test"));
                            adapter.activate();
                            serverReady();
                            communicator.waitForShutdown();
                        }
                    }

                    public static int Main(string[] args)
                    {
                        return TestDriver.runTest<Server>(args);
                    }
                }
            }
        }
    }
}
