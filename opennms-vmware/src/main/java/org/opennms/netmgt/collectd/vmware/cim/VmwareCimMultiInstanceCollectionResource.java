/*******************************************************************************
 * This file is part of OpenNMS(R).
 *
 * Copyright (C) 2009-2011 The OpenNMS Group, Inc.
 * OpenNMS(R) is Copyright (C) 1999-2011 The OpenNMS Group, Inc.
 *
 * OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
 *
 * OpenNMS(R) is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * OpenNMS(R) is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenNMS(R).  If not, see:
 *      http://www.gnu.org/licenses/
 *
 * For more information contact:
 *     OpenNMS(R) Licensing <license@opennms.org>
 *     http://www.opennms.org/
 *     http://www.opennms.com/
 *******************************************************************************/

package org.opennms.netmgt.collectd.vmware.cim;

import org.opennms.core.utils.LogUtils;
import org.opennms.netmgt.collectd.CollectionAgent;
import org.opennms.netmgt.model.RrdRepository;

import java.io.File;

public class VmwareCimMultiInstanceCollectionResource extends VmwareCimCollectionResource {
    private String m_inst;
    private String m_name;

    public VmwareCimMultiInstanceCollectionResource(final CollectionAgent agent, final String instance, final String name) {
        super(agent);
        m_inst = instance;
        m_name = name;
    }

    @Override
    public File getResourceDir(RrdRepository repository) {
        final File rrdBaseDir = repository.getRrdBaseDir();
        final File nodeDir = new File(rrdBaseDir, String.valueOf(m_agent.getNodeId()));
        final File typeDir = new File(nodeDir, m_name);
        final File instDir = new File(typeDir, m_inst.replaceAll("/","_").replaceAll("\\s+", "_").replaceAll(":", "_").replaceAll("\\\\", "_").replaceAll("[\\[\\]]", "_"));
        LogUtils.debugf(this, "getResourceDir: %s", instDir);
        return instDir;
    }

    public String getResourceTypeName() {
        return m_name;
    }

    public String getInstance() {
        return m_inst;
    }

    public String toString() {
        return "Node[" + m_agent.getNodeId() + "]/type["+ m_name+"]/instance[" + m_inst +"]";
    }
}
